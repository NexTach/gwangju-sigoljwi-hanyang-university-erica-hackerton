import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_config.dart';
import '../core/models.dart';
import '../sensing/calibration.dart';
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
