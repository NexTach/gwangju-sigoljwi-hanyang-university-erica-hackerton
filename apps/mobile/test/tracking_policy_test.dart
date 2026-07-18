import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/core/models.dart';
import 'package:road_dna_mobile/state/tracking_controller.dart';

LocationReading locationWithSpeed(double speed) => LocationReading(
  accuracy: 4,
  latitude: 35.15958,
  longitude: 126.85261,
  recordedAt: DateTime.utc(2026, 7, 18),
  speed: speed,
);

void main() {
  test('motion analysis only runs while GPS reports movement', () {
    expect(isMotionAnalysisEligible(null), isFalse);
    expect(isMotionAnalysisEligible(locationWithSpeed(0.24)), isFalse);
    expect(isMotionAnalysisEligible(locationWithSpeed(0.25)), isTrue);
  });

  test('only accepted impacts and held drops create user feedback', () {
    expect(shouldSurfaceCandidateFeedback('ACCEPTED'), isTrue);
    expect(shouldSurfaceCandidateFeedback('HELD_DROP_PATTERN'), isTrue);
    expect(shouldSurfaceCandidateFeedback('REJECTED_STATIONARY'), isFalse);
    expect(shouldSurfaceCandidateFeedback('REJECTED_BELOW_THRESHOLD'), isFalse);
    expect(shouldSurfaceCandidateFeedback('HELD_LOW_GPS_ACCURACY'), isFalse);
  });
}
