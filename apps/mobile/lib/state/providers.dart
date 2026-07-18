import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_config.dart';
import '../core/models.dart';
import '../sensing/calibration.dart';
import '../sensing/window_analyzer.dart';
import '../services/api_service.dart';
import '../services/contribution_store.dart';
import '../services/identity_service.dart';
import '../services/location_service.dart';
import '../services/motion_sensor_service.dart';

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final identityServiceProvider = Provider<IdentityService>(
  (ref) => IdentityService(),
);

final locationServiceProvider = Provider<LocationService>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.demoMode
      ? const DemoLocationService()
      : const DeviceLocationService();
});

final motionSensorServiceProvider = Provider<MotionSensorService>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.demoMode
      ? const DemoMotionSensorService()
      : const DeviceMotionSensorService();
});

final apiProvider = Provider<RoadDnaApi>(
  (ref) => RoadDnaApi(ref.watch(appConfigProvider)),
);

final calibrationStoreProvider = Provider<CalibrationStore>(
  (ref) => CalibrationStore(),
);

final contributionStoreProvider = Provider<ContributionStore>(
  (ref) => ContributionStore(),
);

final anonymousIdentityProvider = FutureProvider<String>(
  (ref) => ref.watch(identityServiceProvider).getOrCreate(),
);

final locationAccessProvider = FutureProvider<LocationAccess>(
  (ref) => ref.watch(locationServiceProvider).checkAccess(),
);

final currentLocationProvider = StreamProvider<LocationReading>(
  (ref) => ref.watch(locationServiceProvider).watch(),
);

@immutable
class SensorPreview {
  const SensorPreview({
    required this.linearMagnitude,
    required this.rawMagnitude,
    required this.recordedAt,
    required this.sampleRateHz,
    required this.x,
    required this.y,
    required this.z,
  });

  final double linearMagnitude;
  final double rawMagnitude;
  final DateTime recordedAt;
  final double sampleRateHz;
  final double x;
  final double y;
  final double z;
}

final sensorPreviewProvider = StreamProvider.autoDispose<SensorPreview>((
  ref,
) async* {
  final gravityFilter = GravityFilter();
  DateTime? previousAt;
  var sampleRateHz = 0.0;
  await for (final raw in ref.watch(motionSensorServiceProvider).watch()) {
    final linear = gravityFilter.filter(raw);
    final previous = previousAt;
    if (previous != null) {
      final elapsedMicros = raw.recordedAt.difference(previous).inMicroseconds;
      if (elapsedMicros > 0) {
        final currentRate = 1000000 / elapsedMicros;
        if (currentRate >= 1 && currentRate <= 200) {
          sampleRateHz = sampleRateHz == 0
              ? currentRate
              : sampleRateHz * 0.85 + currentRate * 0.15;
        }
      }
    }
    previousAt = raw.recordedAt;
    yield SensorPreview(
      linearMagnitude: linear.magnitude,
      rawMagnitude: raw.magnitude,
      recordedAt: raw.recordedAt,
      sampleRateHz: sampleRateHz,
      x: linear.x,
      y: linear.y,
      z: linear.z,
    );
  }
});

final calibrationProvider = FutureProvider<CalibrationSettings>(
  (ref) => ref.watch(calibrationStoreProvider).read(),
);

final contributionProvider = FutureProvider<ContributionSummary>(
  (ref) => ref.watch(contributionStoreProvider).read(),
);

@immutable
class NearbyRoadRequest {
  const NearbyRoadRequest({
    required this.latitude,
    required this.longitude,
    required this.movementType,
  });

  final double latitude;
  final double longitude;
  final MovementType movementType;

  @override
  bool operator ==(Object other) =>
      other is NearbyRoadRequest &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.movementType == movementType;

  @override
  int get hashCode => Object.hash(latitude, longitude, movementType);
}

final nearbyRoadsProvider =
    FutureProvider.family<List<RoadMapItem>, NearbyRoadRequest>(
      (ref, request) => ref
          .watch(apiProvider)
          .nearbyRoads(
            latitude: request.latitude,
            longitude: request.longitude,
            movementType: request.movementType,
          ),
    );

final roadDetailProvider = FutureProvider.family<RoadDetail, String>(
  (ref, roadSegmentId) =>
      ref.watch(apiProvider).roadDetail(roadSegmentId),
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggle(Brightness brightness) {
    final isDark =
        state == ThemeMode.dark ||
        (state == ThemeMode.system && brightness == Brightness.dark);
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(
      ThemeModeController.new,
    );
