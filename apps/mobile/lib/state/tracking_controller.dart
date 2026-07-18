import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/geo.dart';
import '../core/models.dart';
import '../sensing/window_analyzer.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'providers.dart';

enum TrackingStatus { idle, starting, active, stopping, completed, failure }

@immutable
class DetectedBarrier {
  const DetectedBarrier({
    required this.candidate,
    required this.eventId,
    required this.location,
    required this.status,
  });

  final ImpactCandidate candidate;
  final String eventId;
  final LocationReading location;
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
    required this.status,
    this.errorMessage,
    this.lastCandidate,
    this.latestLocation,
    this.movementType,
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
    session: session ?? this.session,
    status: status ?? this.status,
  );
}

class TrackingController extends Notifier<TrackingState> {
  StreamSubscription<LocationReading>? _locationSubscription;
  StreamSubscription<MotionSample>? _motionSubscription;
  SensorWindowAnalyzer? _analyzer;
  LocationReading? _distanceAnchor;
  DateTime _lastTelemetryUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  TrackingState build() {
    ref.onDispose(() {
      unawaited(_locationSubscription?.cancel());
      unawaited(_motionSubscription?.cancel());
    });
    return const TrackingState.idle();
  }

  Future<bool> start(MovementType movementType) async {
    if (state.status == TrackingStatus.starting ||
        state.status == TrackingStatus.active) {
      return false;
    }
    state = const TrackingState.idle().copyWith(
      movementType: movementType,
      status: TrackingStatus.starting,
    );
    final locationService = ref.read(locationServiceProvider);
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
      final identity = await ref.read(anonymousIdentityProvider.future);
      final api = ref.read(apiProvider);
      session = await api.startSession(
        anonymousUserId: identity,
        movementType: movementType,
      );
      final calibration = await ref.read(calibrationProvider.future);
      _analyzer = SensorWindowAnalyzer(calibration: calibration);
      final initialLocation = await locationService.current();
      _distanceAnchor = initialLocation;
      state = state.copyWith(
        latestLocation: initialLocation,
        session: session,
        status: TrackingStatus.active,
      );
      _locationSubscription = locationService.watch().listen(
        _onLocation,
        onError: (Object error, StackTrace stackTrace) {
          state = state.copyWith(errorMessage: 'GPS 신호가 잠시 끊겼어요.');
        },
      );
      _motionSubscription = ref.read(motionSensorServiceProvider).watch().listen(
        _onMotion,
        onError: (Object error, StackTrace stackTrace) {
          state = state.copyWith(
            errorMessage: '이 기기에서 모션 센서를 읽을 수 없어요.',
          );
        },
      );
      ref.invalidate(locationAccessProvider);
      return true;
    } catch (error) {
      if (session != null) {
        await ref.read(apiProvider).endSession(session.sessionId).catchError(
          (_) {},
        );
      }
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
    await Future.wait([
      _locationSubscription?.cancel() ?? Future<void>.value(),
      _motionSubscription?.cancel() ?? Future<void>.value(),
    ]);
    _locationSubscription = null;
    _motionSubscription = null;
    _analyzer?.reset();
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
        errorMessage:
            '${_messageFor(error)} 측정은 기기에서 안전하게 종료했어요.',
        status: TrackingStatus.completed,
      );
    }
  }

  void reset() {
    _distanceAnchor = null;
    _analyzer?.reset();
    state = const TrackingState.idle();
  }

  Future<void> injectDebugImpact() async {
    if (state.status != TrackingStatus.active) return;
    final now = DateTime.now().toUtc();
    await _handleCandidate(
      ImpactCandidate(
        anomalyScore: 0.86,
        detectedAt: now,
        features: const SensorWindowFeatures(
          duration: Duration(seconds: 2),
          gyroRms: 1.8,
          maxPeak: 6.4,
          mean: 1.4,
          peakCount: 3,
          rms: 2.2,
          standardDeviation: 1.1,
        ),
        impactLevel: ImpactLevel.high,
        isPossibleDrop: false,
        severity: 0.86,
      ),
    );
  }

  void _onLocation(LocationReading location) {
    if (state.status != TrackingStatus.active) return;
    final anchor = _distanceAnchor;
    var distance = state.distanceMeters;
    if (anchor != null &&
        location.accuracy <= 30 &&
        anchor.accuracy <= 30 &&
        location.speed >= 0.25) {
      final delta = distanceMeters(
        firstLatitude: anchor.latitude,
        firstLongitude: anchor.longitude,
        secondLatitude: location.latitude,
        secondLongitude: location.longitude,
      );
      if (delta <= 100) distance += delta;
    }
    _distanceAnchor = location;
    state = state.copyWith(
      distanceMeters: distance,
      latestLocation: location,
    );
  }

  void _onMotion(MotionSample sample) {
    if (state.status != TrackingStatus.active) return;
    final now = sample.recordedAt;
    if (now.difference(_lastTelemetryUpdate) >=
        const Duration(milliseconds: 250)) {
      _lastTelemetryUpdate = now;
      state = state.copyWith(lastSensorMagnitude: sample.magnitude);
    }
    final candidate = _analyzer?.add(sample);
    if (candidate != null) unawaited(_handleCandidate(candidate));
  }

  Future<void> _handleCandidate(ImpactCandidate candidate) async {
    final location = state.latestLocation;
    final session = state.session;
    final movementType = state.movementType;
    if (location == null || session == null || movementType == null) {
      state = state.copyWith(
        heldEvents: state.heldEvents + 1,
        lastCandidate: candidate,
      );
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
      if (state.session?.sessionId != session.sessionId) return;
      final accepted = receipt.status == 'ACCEPTED';
      final barrier = DetectedBarrier(
        candidate: candidate,
        eventId: receipt.eventId,
        location: location,
        status: receipt.status,
      );
      state = state.copyWith(
        acceptedEvents: state.acceptedEvents + (accepted ? 1 : 0),
        barriers: accepted ? [...state.barriers, barrier] : state.barriers,
        feedbackSequence: state.feedbackSequence + 1,
        heldEvents: state.heldEvents + (accepted ? 0 : 1),
        lastCandidate: candidate,
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: _messageFor(error),
        heldEvents: state.heldEvents + 1,
        lastCandidate: candidate,
      );
    }
  }

  String _permissionMessage(LocationAccess access) => switch (access) {
    LocationAccess.denied => '위치 권한이 있어야 측정을 시작할 수 있어요.',
    LocationAccess.deniedForever => '설정에서 Road DNA 위치 권한을 허용해 주세요.',
    LocationAccess.serviceDisabled => '기기의 위치 서비스를 켜 주세요.',
    LocationAccess.granted => '',
  };

  String _messageFor(Object error) => switch (error) {
    RoadDnaApiException(:final message) => message,
    _ => '측정을 시작하지 못했어요. 센서와 네트워크를 확인해 주세요.',
  };
}

final trackingProvider =
    NotifierProvider<TrackingController, TrackingState>(
      TrackingController.new,
    );
