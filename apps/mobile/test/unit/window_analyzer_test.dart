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
  recordedAt: DateTime.utc(2026, 7, 18).add(Duration(milliseconds: index * 40)),
  x: x,
  y: y,
  z: z,
);

void main() {
  group('Describe SensorWindowAnalyzer.add', () {
    group('Context 안정적인 중력 벡터만 측정된 경우', () {
      test('It 충격 후보를 만들지 않는다', () {
        final analyzer = SensorWindowAnalyzer(
          calibration: const CalibrationSettings.exploratory(),
        );
        ImpactCandidate? candidate;
        for (var index = 0; index <= 50; index += 1) {
          candidate = analyzer.add(sampleAt(index));
        }

        expect(candidate, isNull);
      });
    });

    group('Context 일상적인 단일 취급 움직임이 들어온 경우', () {
      test('It 노면 충격으로 오인하지 않는다', () {
        final analyzer = SensorWindowAnalyzer(
          calibration: const CalibrationSettings.exploratory(),
        );
        ImpactCandidate? candidate;
        for (var index = 0; index <= 50; index += 1) {
          candidate = analyzer.add(
            sampleAt(
              index,
              gyro: index == 34 ? 1.2 : 0,
              x: index == 34 ? 2.8 : 0,
            ),
          );
        }

        expect(candidate, isNull);
      });
    });

    group('Context 낮은 에너지의 취급 움직임이 반복된 경우', () {
      test('It 노면 충격으로 오인하지 않는다', () {
        final analyzer = SensorWindowAnalyzer(
          calibration: const CalibrationSettings.exploratory(),
        );
        ImpactCandidate? candidate;
        for (var index = 0; index <= 50; index += 1) {
          final movement = index == 28 || index == 38 ? 2.1 : 0.0;
          candidate = analyzer.add(
            sampleAt(index, gyro: movement > 0 ? 1.4 : 0, x: movement),
          );
        }

        expect(candidate, isNull);
      });
    });

    group('Context 2초 창에서 높은 충격이 반복된 경우', () {
      test('It 최고 피크 시각을 가진 고충격 후보를 만든다', () {
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
        expect(candidate.detectedAt, sampleAt(32).recordedAt);
      });
    });

    group('Context 극단적인 단일 피크가 감지된 경우', () {
      test('It 휴대전화 낙하 의심으로 분류한다', () {
        final analyzer = SensorWindowAnalyzer(
          calibration: const CalibrationSettings.exploratory(),
        );
        ImpactCandidate? candidate;
        for (var index = 0; index <= 50; index += 1) {
          candidate = analyzer.add(sampleAt(index, x: index == 35 ? 35 : 0));
        }

        expect(candidate, isNotNull);
        expect(candidate!.isPossibleDrop, isTrue);
        expect(candidate.detectedAt, sampleAt(35).recordedAt);
      });
    });

    group('Context 센서 스트림 중간에 긴 공백이 생긴 경우', () {
      test('It 이전 샘플을 버리고 새 분석 창을 시작한다', () {
        final analyzer = SensorWindowAnalyzer(
          calibration: const CalibrationSettings.exploratory(),
        );
        ImpactCandidate? candidate;
        for (var index = 0; index <= 30; index += 1) {
          candidate = analyzer.add(sampleAt(index));
        }
        for (var index = 75; index <= 125; index += 1) {
          final impact = index == 100 || index == 105 || index == 110
              ? 8.0
              : 0.0;
          candidate = analyzer.add(
            sampleAt(index, gyro: impact > 0 ? 2.4 : 0.2, x: impact),
          );
        }

        expect(candidate, isNotNull);
        expect(candidate!.features.duration, const Duration(seconds: 2));
      });
    });

    group('Context 유효 샘플 주기가 최소 기준보다 낮은 경우', () {
      test('It 분석 결과를 폐기한다', () {
        final analyzer = SensorWindowAnalyzer(
          calibration: const CalibrationSettings.exploratory(),
          maximumSampleGap: const Duration(milliseconds: 250),
          minimumSamples: 5,
        );
        ImpactCandidate? candidate;
        for (var index = 0; index <= 10; index += 1) {
          candidate = analyzer.add(sampleAt(index * 5, x: index == 7 ? 35 : 0));
        }

        expect(candidate, isNull);
      });
    });
  });

  group('Describe GravityFilter.filter', () {
    group('Context 샘플 시각에 긴 공백이 생긴 경우', () {
      test('It 중력 기준을 현재 샘플로 다시 설정한다', () {
        final filter = GravityFilter();
        final first = filter.filter(sampleAt(0, x: 1));
        final continuous = filter.filter(sampleAt(1, x: 3));
        final afterGap = filter.filter(sampleAt(20, x: 9));

        expect(first.magnitude, 0);
        expect(continuous.magnitude, greaterThan(0));
        expect(afterGap.magnitude, 0);
      });
    });
  });

  group('Describe CalibrationSettings.isValid', () {
    group('Context 충격 임계값 순서를 검증하는 경우', () {
      test('It 낮음·중간·높음·낙하가 증가할 때만 허용한다', () {
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
    });
  });
}
