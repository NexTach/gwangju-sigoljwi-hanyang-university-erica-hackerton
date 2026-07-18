import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/geo.dart';
import '../core/models.dart';
import '../sensing/calibration.dart';
import '../sensing/window_analyzer.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../ui/profile_preferences_state.dart';
import 'providers.dart';

enum TrackingStatus { idle, starting, active, stopping, completed, failure }

bool isMotionAnalysisEligible(
  LocationReading? location, {
  bool allowMockLocations = false,
  DateTime? at,
  bool? moving,
}) =>
    location != null &&
    _isUsableLocation(
      location,
      allowMockLocations: allowMockLocations,
      at: at,
    ) &&
    (moving ?? location.speed >= 0.25);

bool shouldSurfaceCandidateFeedback(String status) =>
    status == 'ACCEPTED' || status == 'HELD_DROP_PATTERN';

bool _isUsableLocation(
  LocationReading location, {
  required bool allowMockLocations,
  DateTime? at,
}) {
  if (!location.accuracy.isFinite ||
      location.accuracy < 0 ||
      location.accuracy > 20 ||
      !location.latitude.isFinite ||
      location.latitude < -90 ||
      location.latitude > 90 ||
      !location.longitude.isFinite ||
      location.longitude < -180 ||
      location.longitude > 180 ||
      !location.speed.isFinite ||
      location.speed < 0 ||
      (location.isMocked && !allowMockLocations)) {
    return false;
  }
  if (at != null &&
      at.difference(location.recordedAt).inMilliseconds.abs() > 5000) {
    return false;
  }
  return true;
}

class LocationQualityFilter {
  LocationQualityFilter({this.allowMockLocations = false});

  final bool allowMockLocations;
  DateTime? _lastObservedAt;

  bool accept(LocationReading location, {DateTime? at}) {
    if (!_isUsableLocation(
      location,
      allowMockLocations: allowMockLocations,
      at: at,
    )) {
      return false;
    }
    final lastObservedAt = _lastObservedAt;
    if (lastObservedAt != null &&
        !location.recordedAt.isAfter(lastObservedAt)) {
      return false;
    }
    _lastObservedAt = location.recordedAt;
    return true;
  }

  void reset() => _lastObservedAt = null;
}

@immutable
class DistanceAccumulatorUpdate {
  const DistanceAccumulatorUpdate({
    required this.addedMeters,
    required this.appendToTrace,
    required this.isMoving,
  });

  final double addedMeters;
  final bool appendToTrace;
  final bool isMoving;
}

class JitterAwareDistanceAccumulator {
  JitterAwareDistanceAccumulator(this.movementType);

  final MovementType movementType;
  LocationReading? _anchor;
  var _isMoving = false;
  var _stationaryEvidence = 0;

  bool get isMoving => _isMoving;

  void seed(LocationReading location) {
    _anchor = location;
    _isMoving = location.speed >= 0.35;
    _stationaryEvidence = 0;
  }

  DistanceAccumulatorUpdate add(LocationReading location) {
    final anchor = _anchor;
    if (anchor == null) {
      seed(location);
      return DistanceAccumulatorUpdate(
        addedMeters: 0,
        appendToTrace: true,
        isMoving: _isMoving,
      );
    }
    final elapsed = location.recordedAt.difference(anchor.recordedAt);
    if (elapsed <= Duration.zero) {
      return DistanceAccumulatorUpdate(
        addedMeters: 0,
        appendToTrace: false,
        isMoving: _isMoving,
      );
    }
    if (elapsed > const Duration(seconds: 10)) {
      seed(location);
      return DistanceAccumulatorUpdate(
        addedMeters: 0,
        appendToTrace: true,
        isMoving: _isMoving,
      );
    }

    final delta = distanceMeters(
      firstLatitude: anchor.latitude,
      firstLongitude: anchor.longitude,
      secondLatitude: location.latitude,
      secondLongitude: location.longitude,
    );
    final elapsedSeconds =
        elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final derivedSpeed = delta / elapsedSeconds;
    final reportedSpeedIsReliable =
        location.speedAccuracy != null && location.speedAccuracy! <= 1.5;
    final effectiveSpeed = reportedSpeedIsReliable
        ? location.speed
        : derivedSpeed;
    _updateMovementState(effectiveSpeed);

    final noiseFloor = _maxOf(
      2.5,
      _minOf(6, (anchor.accuracy + location.accuracy) * 0.35),
    );
    final maximumSpeed = switch (movementType) {
      MovementType.walking => 4.0,
      MovementType.wheelchair => 5.0,
      MovementType.stroller => 5.0,
    };
    final plausibleDistance = maximumSpeed * elapsedSeconds + noiseFloor;
    if (!_isMoving || delta < noiseFloor || delta > plausibleDistance) {
      return DistanceAccumulatorUpdate(
        addedMeters: 0,
        appendToTrace: false,
        isMoving: _isMoving,
      );
    }

    _anchor = location;
    return DistanceAccumulatorUpdate(
      addedMeters: delta,
      appendToTrace: true,
      isMoving: _isMoving,
    );
  }

  void reset() {
    _anchor = null;
    _isMoving = false;
    _stationaryEvidence = 0;
  }

  void _updateMovementState(double speed) {
    if (speed >= 0.35) {
      _isMoving = true;
      _stationaryEvidence = 0;
      return;
    }
    if (speed <= 0.15) {
      _stationaryEvidence += 1;
      if (_stationaryEvidence >= 3) _isMoving = false;
      return;
    }
    _stationaryEvidence = 0;
  }
}

double _maxOf(double first, double second) => first > second ? first : second;

double _minOf(double first, double second) => first < second ? first : second;

@immutable
class DetectedBarrier {
  const DetectedBarrier({
    required this.candidate,
    required this.eventId,
    required this.location,
    required this.status,
    this.roadSegmentId,
  });

  final ImpactCandidate candidate;
  final String eventId;
  final LocationReading location;
  final String? roadSegmentId;
  final String status;
}

@immutable
class TrackingState {
  const TrackingState({
    required this.acceptedEvents,
    required this.barriers,
    required this.distanceMeters,
    required this.feedbackSequence,
    required this.heldEvents,
    required this.lastSensorMagnitude,
    required this.routeTrace,
    required this.status,
    this.errorMessage,
    this.lastCandidate,
    this.latestLocation,
    this.movementType,
    this.selectedRoute,
    this.session,
  });

  const TrackingState.idle()
    : acceptedEvents = 0,
      barriers = const [],
      distanceMeters = 0,
      errorMessage = null,
      feedbackSequence = 0,
      heldEvents = 0,
      lastCandidate = null,
      lastSensorMagnitude = 0,
      latestLocation = null,
      movementType = null,
      routeTrace = const [],
      selectedRoute = null,
      session = null,
      status = TrackingStatus.idle;

  final int acceptedEvents;
  final List<DetectedBarrier> barriers;
  final double distanceMeters;
  final String? errorMessage;
  final int feedbackSequence;
  final int heldEvents;
  final ImpactCandidate? lastCandidate;
  final double lastSensorMagnitude;
  final LocationReading? latestLocation;
  final MovementType? movementType;
  final List<LocationReading> routeTrace;
  final RouteOption? selectedRoute;
  final MovementSession? session;
  final TrackingStatus status;

  TrackingState copyWith({
    int? acceptedEvents,
    List<DetectedBarrier>? barriers,
    double? distanceMeters,
    String? errorMessage,
    bool clearError = false,
    int? feedbackSequence,
    int? heldEvents,
    ImpactCandidate? lastCandidate,
    double? lastSensorMagnitude,
    LocationReading? latestLocation,
    MovementType? movementType,
    List<LocationReading>? routeTrace,
    RouteOption? selectedRoute,
    MovementSession? session,
    TrackingStatus? status,
  }) => TrackingState(
    acceptedEvents: acceptedEvents ?? this.acceptedEvents,
    barriers: barriers ?? this.barriers,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    feedbackSequence: feedbackSequence ?? this.feedbackSequence,
    heldEvents: heldEvents ?? this.heldEvents,
    lastCandidate: lastCandidate ?? this.lastCandidate,
    lastSensorMagnitude: lastSensorMagnitude ?? this.lastSensorMagnitude,
    latestLocation: latestLocation ?? this.latestLocation,
    movementType: movementType ?? this.movementType,
    routeTrace: routeTrace ?? this.routeTrace,
    selectedRoute: selectedRoute ?? this.selectedRoute,
    session: session ?? this.session,
    status: status ?? this.status,
  );
}

class TrackingController extends Notifier<TrackingState> {
  StreamSubscription<LocationReading>? _locationSubscription;
  StreamSubscription<MotionSample>? _motionSubscription;
  SensorWindowAnalyzer? _analyzer;
  final GravityFilter _telemetryGravityFilter = GravityFilter();
  LocationQualityFilter? _locationQualityFilter;
  JitterAwareDistanceAccumulator? _distanceAccumulator;
  final List<LocationReading> _recentLocations = [];
  DateTime _lastTelemetryUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _allowMockLocations = false;
  bool _wasMotionAnalysisEligible = false;

  @override
  TrackingState build() {
    ref.onDispose(() {
      unawaited(_cancelSubscriptions());
      _resetRuntime();
    });
    return const TrackingState.idle();
  }

  Future<bool> start(MovementType movementType, {RouteOption? route}) async {
    if (state.status == TrackingStatus.starting ||
        state.status == TrackingStatus.active) {
      return false;
    }
    await _cancelSubscriptions();
    _resetRuntime();
    final demoMode = ref.read(appConfigProvider).demoMode;
    _allowMockLocations = demoMode;
    _locationQualityFilter = LocationQualityFilter(
      allowMockLocations: _allowMockLocations,
    );
    _distanceAccumulator = JitterAwareDistanceAccumulator(movementType);
    state = const TrackingState.idle().copyWith(
      movementType: movementType,
      selectedRoute: route,
      status: TrackingStatus.starting,
    );
    final baseLocationService = ref.read(locationServiceProvider);
    final locationService =
        demoMode && route != null && baseLocationService is DemoLocationService
        ? baseLocationService.followingRoute(route.coordinates)
        : baseLocationService;
    MovementSession? session;
    try {
      final access = await locationService.ensureAccess();
      if (access != LocationAccess.granted) {
        state = state.copyWith(
          errorMessage: _permissionMessage(access),
          status: TrackingStatus.failure,
        );
        ref.invalidate(locationAccessProvider);
        return false;
      }
      final initialLocation = await locationService.current();
      if (!_locationQualityFilter!.accept(initialLocation)) {
        throw const _LocationQualityException();
      }
      _distanceAccumulator!.seed(initialLocation);
      _rememberLocation(initialLocation);
      final calibration = demoMode
          ? const CalibrationSettings.exploratory()
          : await ref.read(calibrationProvider.future);
      _analyzer = SensorWindowAnalyzer(calibration: calibration);
      final identity = await ref.read(anonymousIdentityProvider.future);
      final api = ref.read(apiProvider);
      session = await api.startSession(
        anonymousUserId: identity,
        movementType: movementType,
      );
      state = state.copyWith(
        clearError: true,
        latestLocation: initialLocation,
        routeTrace: [initialLocation],
        session: session,
        status: TrackingStatus.active,
      );
      _locationSubscription = locationService.watch().listen(
        _onLocation,
        onError: (Object error, StackTrace stackTrace) {
          _recentLocations.clear();
          _analyzer?.reset();
          _wasMotionAnalysisEligible = false;
          state = state.copyWith(errorMessage: 'GPS 신호가 잠시 끊겼어요.');
        },
      );
      _motionSubscription = ref
          .read(motionSensorServiceProvider)
          .watch()
          .listen(
            _onMotion,
            onError: (Object error, StackTrace stackTrace) {
              _analyzer?.reset();
              _telemetryGravityFilter.reset();
              _wasMotionAnalysisEligible = false;
              state = state.copyWith(errorMessage: '이 기기에서 모션 센서를 읽을 수 없어요.');
            },
          );
      ref.invalidate(locationAccessProvider);
      return true;
    } catch (error) {
      await _cancelSubscriptions();
      if (session != null) {
        await ref
            .read(apiProvider)
            .endSession(session.sessionId)
            .catchError((_) {});
      }
      _resetRuntime();
      state = state.copyWith(
        errorMessage: _messageFor(error),
        status: TrackingStatus.failure,
      );
      return false;
    }
  }

  Future<void> stop() async {
    final session = state.session;
    if (session == null || state.status != TrackingStatus.active) return;
    state = state.copyWith(status: TrackingStatus.stopping);
    await _cancelSubscriptions();
    try {
      await ref.read(apiProvider).endSession(session.sessionId);
      await ref
          .read(contributionStoreProvider)
          .addSession(
            acceptedEvents: state.acceptedEvents,
            distanceMeters: state.distanceMeters,
          );
      ref.invalidate(contributionProvider);
      state = state.copyWith(
        clearError: true,
        status: TrackingStatus.completed,
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: '${_messageFor(error)} 측정은 기기에서 안전하게 종료했어요.',
        status: TrackingStatus.completed,
      );
    } finally {
      _resetRuntime();
    }
  }

  void reset() {
    final session = state.session;
    final shouldEndSession =
        state.status == TrackingStatus.active ||
        state.status == TrackingStatus.starting ||
        state.status == TrackingStatus.stopping;
    unawaited(_cancelSubscriptions());
    if (session != null && shouldEndSession) {
      unawaited(
        ref.read(apiProvider).endSession(session.sessionId).catchError((_) {}),
      );
    }
    _resetRuntime();
    state = const TrackingState.idle();
  }

  void _onLocation(LocationReading location) {
    if (state.status != TrackingStatus.active) return;
    if (!(_locationQualityFilter?.accept(location) ?? false)) return;
    _rememberLocation(location);
    final update = _distanceAccumulator?.add(location);
    var trace = state.routeTrace;
    if (update?.appendToTrace == true) {
      trace = [...trace, location];
      if (trace.length > 2500) {
        trace = trace.sublist(trace.length - 2500);
      }
    }
    state = state.copyWith(
      clearError: true,
      distanceMeters: state.distanceMeters + (update?.addedMeters ?? 0),
      latestLocation: location,
      routeTrace: trace,
    );
  }

  void _onMotion(MotionSample sample) {
    if (state.status != TrackingStatus.active) return;
    final linearSample = _telemetryGravityFilter.filter(sample);
    final now = sample.recordedAt;
    if (now.difference(_lastTelemetryUpdate) >=
        const Duration(milliseconds: 250)) {
      _lastTelemetryUpdate = now;
      state = state.copyWith(lastSensorMagnitude: linearSample.magnitude);
    }
    final location = _nearestFreshLocation(sample.recordedAt);
    final isEligible = isMotionAnalysisEligible(
      location,
      allowMockLocations: _allowMockLocations,
      at: sample.recordedAt,
      moving: _distanceAccumulator?.isMoving ?? false,
    );
    if (!isEligible) {
      if (_wasMotionAnalysisEligible) _analyzer?.reset();
      _wasMotionAnalysisEligible = false;
      return;
    }
    _wasMotionAnalysisEligible = true;
    final candidate = _analyzer?.add(sample);
    if (candidate != null) unawaited(_handleCandidate(candidate));
  }

  Future<void> _handleCandidate(ImpactCandidate candidate) async {
    final location = _nearestFreshLocation(candidate.detectedAt);
    final session = state.session;
    final movementType = state.movementType;
    if (location == null || session == null || movementType == null) {
      state = state.copyWith(heldEvents: state.heldEvents + 1);
      return;
    }
    try {
      final receipt = await ref
          .read(apiProvider)
          .sendCandidate(
            candidate: candidate,
            location: location,
            movementType: movementType,
            sessionId: session.sessionId,
          );
      if (state.session?.sessionId != session.sessionId ||
          state.status != TrackingStatus.active) {
        return;
      }
      final accepted = receipt.status == 'ACCEPTED';
      final shouldSurface =
          shouldSurfaceCandidateFeedback(receipt.status) &&
          ref
              .read(profilePreferencesProvider)
              .allowsNotification(ProfileNotificationChannel.impact);
      final barrier = DetectedBarrier(
        candidate: candidate,
        eventId: receipt.eventId,
        location: location,
        roadSegmentId: receipt.roadSegmentId,
        status: receipt.status,
      );
      state = state.copyWith(
        acceptedEvents: state.acceptedEvents + (accepted ? 1 : 0),
        barriers: accepted ? [...state.barriers, barrier] : state.barriers,
        feedbackSequence: state.feedbackSequence + (shouldSurface ? 1 : 0),
        heldEvents: state.heldEvents + (accepted ? 0 : 1),
        lastCandidate: shouldSurface ? candidate : state.lastCandidate,
      );
    } catch (error) {
      if (state.session?.sessionId != session.sessionId ||
          state.status != TrackingStatus.active) {
        return;
      }
      state = state.copyWith(
        errorMessage: _messageFor(error),
        heldEvents: state.heldEvents + 1,
      );
    }
  }

  Future<void> _cancelSubscriptions() async {
    final locationSubscription = _locationSubscription;
    final motionSubscription = _motionSubscription;
    _locationSubscription = null;
    _motionSubscription = null;
    await Future.wait([
      locationSubscription?.cancel() ?? Future<void>.value(),
      motionSubscription?.cancel() ?? Future<void>.value(),
    ]);
  }

  void _rememberLocation(LocationReading location) {
    _recentLocations.add(location);
    final oldestUsefulAt = location.recordedAt.subtract(
      const Duration(seconds: 10),
    );
    _recentLocations.removeWhere(
      (reading) => reading.recordedAt.isBefore(oldestUsefulAt),
    );
    if (_recentLocations.length > 64) {
      _recentLocations.removeRange(0, _recentLocations.length - 64);
    }
  }

  LocationReading? _nearestFreshLocation(DateTime at) {
    LocationReading? nearest;
    int? nearestDifference;
    for (final location in _recentLocations) {
      if (!_isUsableLocation(
        location,
        allowMockLocations: _allowMockLocations,
        at: at,
      )) {
        continue;
      }
      final difference = at
          .difference(location.recordedAt)
          .inMicroseconds
          .abs();
      if (nearestDifference == null || difference < nearestDifference) {
        nearest = location;
        nearestDifference = difference;
      }
    }
    return nearest;
  }

  void _resetRuntime() {
    _analyzer?.reset();
    _analyzer = null;
    _telemetryGravityFilter.reset();
    _locationQualityFilter?.reset();
    _locationQualityFilter = null;
    _distanceAccumulator?.reset();
    _distanceAccumulator = null;
    _recentLocations.clear();
    _lastTelemetryUpdate = DateTime.fromMillisecondsSinceEpoch(0);
    _allowMockLocations = false;
    _wasMotionAnalysisEligible = false;
  }

  String _permissionMessage(LocationAccess access) => switch (access) {
    LocationAccess.denied => '위치 권한이 있어야 측정을 시작할 수 있어요.',
    LocationAccess.deniedForever => '설정에서 Road DNA 위치 권한을 허용해 주세요.',
    LocationAccess.serviceDisabled => '기기의 위치 서비스를 켜 주세요.',
    LocationAccess.granted => '',
  };

  String _messageFor(Object error) => switch (error) {
    RoadDnaApiException(:final message) => message,
    _LocationQualityException() => '정확한 GPS 신호를 확인한 뒤 다시 시작해 주세요.',
    _ => '측정을 시작하지 못했어요. 센서와 네트워크를 확인해 주세요.',
  };
}

class _LocationQualityException implements Exception {
  const _LocationQualityException();
}

final trackingProvider = NotifierProvider<TrackingController, TrackingState>(
  TrackingController.new,
);
