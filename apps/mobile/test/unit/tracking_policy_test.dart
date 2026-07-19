import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/core/models.dart';
import 'package:road_dna_mobile/state/tracking_controller.dart';

final _startedAt = DateTime.utc(2026, 7, 18);

LocationReading _location({
  double accuracy = 4,
  int milliseconds = 0,
  double latitude = 35.15958,
  double longitude = 126.85261,
  bool isMocked = false,
  double speed = 0,
  double? speedAccuracy = 0.2,
}) => LocationReading(
  accuracy: accuracy,
  isMocked: isMocked,
  latitude: latitude,
  longitude: longitude,
  recordedAt: _startedAt.add(Duration(milliseconds: milliseconds)),
  speed: speed,
  speedAccuracy: speedAccuracy,
);

void main() {
  group('Describe isMotionAnalysisEligible', () {
    group('Context 센서 분석에 사용할 GPS를 판단하는 경우', () {
      test('It 정확하고 신선하며 이동 중인 위치만 허용한다', () {
        final analyzedAt = _startedAt.add(const Duration(seconds: 3));

        expect(isMotionAnalysisEligible(null, at: analyzedAt), isFalse);
        expect(
          isMotionAnalysisEligible(_location(speed: 0.24), at: analyzedAt),
          isFalse,
        );
        expect(
          isMotionAnalysisEligible(_location(speed: 0.25), at: analyzedAt),
          isTrue,
        );
        expect(
          isMotionAnalysisEligible(
            _location(accuracy: 21, speed: 1),
            at: analyzedAt,
          ),
          isFalse,
        );
        expect(
          isMotionAnalysisEligible(
            _location(milliseconds: -3000, speed: 1),
            at: analyzedAt,
          ),
          isFalse,
        );
      });
    });

    group('Context 모의 위치가 들어온 경우', () {
      test('It 명시적인 데모 정책에서만 허용한다', () {
        final mocked = _location(isMocked: true, speed: 1);

        expect(isMotionAnalysisEligible(mocked), isFalse);
        expect(
          isMotionAnalysisEligible(mocked, allowMockLocations: true),
          isTrue,
        );
        expect(LocationQualityFilter().accept(mocked), isFalse);
        expect(
          LocationQualityFilter(allowMockLocations: true).accept(mocked),
          isTrue,
        );
      });
    });
  });

  group('Describe LocationQualityFilter.accept', () {
    group('Context 중복되거나 과거 시각의 GPS가 들어온 경우', () {
      test('It 마지막 위치보다 새로운 측정만 허용한다', () {
        final filter = LocationQualityFilter();

        expect(filter.accept(_location()), isTrue);
        expect(filter.accept(_location()), isFalse);
        expect(filter.accept(_location(milliseconds: -1)), isFalse);
        expect(filter.accept(_location(milliseconds: 1)), isTrue);
      });
    });
  });

  group('Describe JitterAwareDistanceAccumulator.add', () {
    group('Context 정지 상태에서 GPS 좌표만 미세하게 흔들리는 경우', () {
      test('It 이동 거리와 경로에 포함하지 않는다', () {
        final accumulator = JitterAwareDistanceAccumulator(
          MovementType.wheelchair,
        )..seed(_location());

        for (var second = 1; second <= 4; second += 1) {
          final update = accumulator.add(
            _location(
              latitude: 35.15958 + second * 0.000009,
              milliseconds: second * 1000,
            ),
          );
          expect(update.addedMeters, 0);
          expect(update.appendToTrace, isFalse);
        }
        expect(accumulator.isMoving, isFalse);
      });
    });

    group('Context 노이즈 범위를 넘는 정상 보행이 이어진 경우', () {
      test('It 실제 이동 거리만 누적한다', () {
        final accumulator = JitterAwareDistanceAccumulator(MovementType.walking)
          ..seed(_location(speed: 1));

        final first = accumulator.add(
          _location(latitude: 35.159589, milliseconds: 1000, speed: 1),
        );
        final second = accumulator.add(
          _location(latitude: 35.159607, milliseconds: 3000, speed: 1),
        );

        expect(first.addedMeters, 0);
        expect(second.addedMeters, greaterThan(2.5));
        expect(second.appendToTrace, isTrue);
        expect(second.isMoving, isTrue);
      });
    });

    group('Context 비현실적인 GPS 순간 이동 뒤 정상 위치가 들어온 경우', () {
      test('It 순간 이동을 버리고 다음 정상 측정을 복구한다', () {
        final accumulator = JitterAwareDistanceAccumulator(MovementType.walking)
          ..seed(_location(speed: 1));

        final jump = accumulator.add(
          _location(latitude: 35.16058, milliseconds: 1000, speed: 1),
        );
        final recovered = accumulator.add(
          _location(latitude: 35.159607, milliseconds: 3000, speed: 1),
        );

        expect(jump.addedMeters, 0);
        expect(jump.appendToTrace, isFalse);
        expect(recovered.addedMeters, greaterThan(2.5));
      });
    });
  });

  group('Describe shouldSurfaceCandidateFeedback', () {
    group('Context 서버 판정 상태를 사용자 알림으로 바꾸는 경우', () {
      test('It 승인된 충격과 낙하 의심만 노출한다', () {
        expect(shouldSurfaceCandidateFeedback('ACCEPTED'), isTrue);
        expect(shouldSurfaceCandidateFeedback('HELD_DROP_PATTERN'), isTrue);
        expect(shouldSurfaceCandidateFeedback('REJECTED_STATIONARY'), isFalse);
        expect(
          shouldSurfaceCandidateFeedback('REJECTED_BELOW_THRESHOLD'),
          isFalse,
        );
        expect(
          shouldSurfaceCandidateFeedback('HELD_LOW_GPS_ACCURACY'),
          isFalse,
        );
      });
    });
  });
}
