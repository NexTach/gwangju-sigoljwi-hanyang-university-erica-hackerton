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
    DateTime? gyroRecordedAt;
    var gyroX = 0.0;
    var gyroY = 0.0;
    var gyroZ = 0.0;
    var finishing = false;

    Future<void> cancelSensors() async {
      final accelerometer = accelerometerSubscription;
      final gyroscope = gyroscopeSubscription;
      accelerometerSubscription = null;
      gyroscopeSubscription = null;
      await Future.wait([
        accelerometer?.cancel() ?? Future<void>.value(),
        gyroscope?.cancel() ?? Future<void>.value(),
      ]);
    }

    Future<void> finish() async {
      if (finishing) return;
      finishing = true;
      await cancelSensors();
      if (!controller.isClosed) await controller.close();
    }

    controller = StreamController<MotionSample>(
      onCancel: cancelSensors,
      onListen: () {
        gyroscopeSubscription =
            gyroscopeEventStream(
              samplingPeriod: const Duration(milliseconds: 40),
            ).listen(
              (event) {
                gyroX = event.x;
                gyroY = event.y;
                gyroZ = event.z;
                gyroRecordedAt = event.timestamp;
              },
              // A gyroscope is optional for impact scoring. Keep accelerometer
              // collection alive on devices without one and score gyro as zero.
              onError: (Object error, StackTrace stackTrace) {
                gyroX = 0;
                gyroY = 0;
                gyroZ = 0;
                gyroRecordedAt = null;
              },
              onDone: () => gyroRecordedAt = null,
              cancelOnError: true,
            );
        accelerometerSubscription =
            accelerometerEventStream(
              samplingPeriod: const Duration(milliseconds: 40),
            ).listen(
              (event) {
                if (controller.isClosed) return;
                final gyroAt = gyroRecordedAt;
                final gyroIsFresh =
                    gyroAt != null &&
                    event.timestamp.difference(gyroAt).inMicroseconds.abs() <=
                        const Duration(milliseconds: 80).inMicroseconds;
                controller.add(
                  MotionSample(
                    gyroX: gyroIsFresh ? gyroX : 0,
                    gyroY: gyroIsFresh ? gyroY : 0,
                    gyroZ: gyroIsFresh ? gyroZ : 0,
                    recordedAt: event.timestamp,
                    x: event.x,
                    y: event.y,
                    z: event.z,
                  ),
                );
              },
              onError: (Object error, StackTrace stackTrace) {
                if (!controller.isClosed) {
                  controller.addError(error, stackTrace);
                }
                unawaited(finish());
              },
              onDone: () => unawaited(finish()),
              cancelOnError: true,
            );
      },
    );
    return controller.stream;
  }
}

class DemoMotionSensorService implements MotionSensorService {
  const DemoMotionSensorService({this.playbackInterval = samplePeriod});

  static const samplePeriod = Duration(milliseconds: 40);
  static const _impactCycleSamples = 306;
  static const _impactOffsets = <int>{132, 137, 142};

  final Duration playbackInterval;

  @override
  Stream<MotionSample> watch() {
    final startedAt = DateTime.now().toUtc();
    return Stream<MotionSample>.periodic(
      playbackInterval,
      (tick) => _scriptedSample(tick, startedAt),
    );
  }

  MotionSample _scriptedSample(int tick, DateTime startedAt) {
    final phase = tick / 4;
    final hasImpact = _impactOffsets.contains(tick % _impactCycleSamples);
    return MotionSample(
      gyroX: hasImpact ? 2.4 : math.sin(phase * 0.7) * 0.18,
      gyroY: hasImpact ? 1.1 : math.cos(phase * 0.55) * 0.16,
      gyroZ: math.sin(phase * 0.3) * 0.12,
      recordedAt: startedAt.add(samplePeriod * tick),
      x: math.sin(phase) * 0.28 + (hasImpact ? 8.0 : 0),
      y: math.cos(phase * 0.8) * 0.22,
      z: 9.81 + math.sin(phase * 0.4) * 0.18,
    );
  }
}
