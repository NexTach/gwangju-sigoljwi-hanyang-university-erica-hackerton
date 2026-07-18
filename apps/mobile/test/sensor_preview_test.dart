import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/core/models.dart';
import 'package:road_dna_mobile/services/motion_sensor_service.dart';
import 'package:road_dna_mobile/state/providers.dart';

class _StationaryMotionSensorService implements MotionSensorService {
  const _StationaryMotionSensorService();

  @override
  Stream<MotionSample> watch() => Stream.value(
    MotionSample(
      gyroX: 0,
      gyroY: 0,
      gyroZ: 0,
      recordedAt: DateTime.utc(2026, 7, 18),
      x: 0,
      y: 0,
      z: 9.81,
    ),
  );
}

void main() {
  test(
    'sensor preview removes gravity without an active tracking session',
    () async {
      final container = ProviderContainer(
        overrides: [
          motionSensorServiceProvider.overrideWithValue(
            const _StationaryMotionSensorService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(sensorPreviewProvider, (_, _) {});
      addTearDown(subscription.close);

      final preview = await container.read(sensorPreviewProvider.future);

      expect(preview.rawMagnitude, closeTo(9.81, 0.001));
      expect(preview.linearMagnitude, closeTo(0, 0.001));
    },
  );
}
