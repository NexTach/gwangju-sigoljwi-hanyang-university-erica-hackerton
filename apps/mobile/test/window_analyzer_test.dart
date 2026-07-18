import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/core/models.dart';
import 'package:road_dna_mobile/sensing/calibration.dart';
import 'package:road_dna_mobile/sensing/window_analyzer.dart';

MotionSample sampleAt(
  int index, {
  double x = 0,
  double y = 0,
  double z = 9.81,
  double gyro = 0,
}) => MotionSample(
  gyroX: gyro,
  gyroY: 0,
  gyroZ: 0,
  recordedAt: DateTime.utc(2026, 7, 18).add(
    Duration(milliseconds: index * 40),
  ),
  x: x,
  y: y,
  z: z,
);

void main() {
  group('SensorWindowAnalyzer', () {
    test('does not turn a stable gravity vector into an impact', () {
      final analyzer = SensorWindowAnalyzer(
        calibration: const CalibrationSettings.exploratory(),
      );
      ImpactCandidate? candidate;
      for (var index = 0; index <= 50; index += 1) {
        candidate = analyzer.add(sampleAt(index));
      }

      expect(candidate, isNull);
    });

    test('extracts a repeated high-impact candidate from a two-second window', () {
      final analyzer = SensorWindowAnalyzer(
        calibration: const CalibrationSettings.exploratory(),
      );
      ImpactCandidate? candidate;
      for (var index = 0; index <= 50; index += 1) {
        final impact = index == 32 || index == 37 || index == 42 ? 8.0 : 0.0;
        candidate = analyzer.add(
          sampleAt(index, gyro: impact > 0 ? 2.4 : 0.2, x: impact),
        );
      }

      expect(candidate, isNotNull);
      expect(candidate!.impactLevel, ImpactLevel.high);
      expect(candidate.features.peakCount, greaterThanOrEqualTo(2));
      expect(candidate.features.gyroRms, greaterThan(0));
      expect(candidate.isPossibleDrop, isFalse);
    });

    test('marks a single extreme peak as a possible phone drop', () {
      final analyzer = SensorWindowAnalyzer(
        calibration: const CalibrationSettings.exploratory(),
      );
      ImpactCandidate? candidate;
      for (var index = 0; index <= 50; index += 1) {
        candidate = analyzer.add(
          sampleAt(index, x: index == 35 ? 35 : 0),
        );
      }

      expect(candidate, isNotNull);
      expect(candidate!.isPossibleDrop, isTrue);
    });
  });

  test('calibration requires increasing impact thresholds', () {
    const invalid = CalibrationSettings(
      dropPeak: 20,
      highImpactPeak: 4,
      lowImpactPeak: 5,
      mediumImpactPeak: 3,
      vibrationRms: 1,
    );
    expect(invalid.isValid, isFalse);
    expect(const CalibrationSettings.exploratory().isValid, isTrue);
  });
}
