import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../core/models.dart';

abstract interface class MotionSensorService {
  Stream<MotionSample> watch();
}

class DeviceMotionSensorService implements MotionSensorService {
  const DeviceMotionSensorService();

  @override
  Stream<MotionSample> watch() {
    late StreamController<MotionSample> controller;
    StreamSubscription<AccelerometerEvent>? accelerometerSubscription;
    StreamSubscription<GyroscopeEvent>? gyroscopeSubscription;
    var gyroX = 0.0;
    var gyroY = 0.0;
    var gyroZ = 0.0;

    controller = StreamController<MotionSample>(
      onCancel: () async {
        await accelerometerSubscription?.cancel();
        await gyroscopeSubscription?.cancel();
      },
      onListen: () {
        gyroscopeSubscription = gyroscopeEventStream(
          samplingPeriod: const Duration(milliseconds: 40),
        ).listen(
          (event) {
            gyroX = event.x;
            gyroY = event.y;
            gyroZ = event.z;
          },
          // A gyroscope is optional for impact scoring. Keep accelerometer
          // collection alive on devices without one and score gyro as zero.
          onError: (Object error, StackTrace stackTrace) {
            gyroX = 0;
            gyroY = 0;
            gyroZ = 0;
          },
        );
        accelerometerSubscription = accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 40),
        ).listen(
          (event) => controller.add(
            MotionSample(
              gyroX: gyroX,
              gyroY: gyroY,
              gyroZ: gyroZ,
              recordedAt: event.timestamp,
              x: event.x,
              y: event.y,
              z: event.z,
            ),
          ),
          onError: controller.addError,
        );
      },
    );
    return controller.stream;
  }
}

class DemoMotionSensorService implements MotionSensorService {
  const DemoMotionSensorService();

  @override
  Stream<MotionSample> watch() => Stream<MotionSample>.periodic(
    const Duration(milliseconds: 40),
    (tick) {
      final phase = tick / 4;
      final impact = tick % 125 >= 60 && tick % 125 <= 64
          ? 6.2 - (tick % 125 - 62).abs() * 1.4
          : 0;
      return MotionSample(
        gyroX: math.sin(phase * 0.7) * 0.4,
        gyroY: math.cos(phase * 0.55) * 0.5,
        gyroZ: math.sin(phase * 0.3) * 0.25,
        recordedAt: DateTime.now().toUtc(),
        x: math.sin(phase) * 0.45 + impact,
        y: math.cos(phase * 0.8) * 0.35,
        z: 9.81 + math.sin(phase * 0.4) * 0.3,
      );
    },
  );
}
