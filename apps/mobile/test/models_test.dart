import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/core/geo.dart';
import 'package:road_dna_mobile/core/models.dart';

void main() {
  test('unknown road score stays null', () {
    final road = RoadMapItem.fromJson({
      'confidence': 0,
      'eventCount': 0,
      'grade': 'UNKNOWN',
      'latitude': 35.1595,
      'longitude': 126.8526,
      'movementType': 'STROLLER',
      'roadName': '분석 전 도로',
      'roadSegmentId': 'd189be1f-e2d5-4b90-8cec-360ec343be99',
      'score': null,
      'updatedAt': '2026-07-18T13:10:00.000Z',
    });

    expect(road.score, isNull);
    expect(road.grade, RoadGrade.unknown);
  });

  test('route geometry converts GeoJSON longitude-latitude order', () {
    final route = RouteOption.fromJson({
      'accessibilityScore': 91,
      'distance': 620,
      'duration': 660,
      'geometry': [
        [126.8526, 35.1595],
        [126.8536, 35.1605],
      ],
      'source': 'ROAD_DNA',
      'type': 'ACCESSIBLE',
    });

    expect(route.coordinates.first.latitude, 35.1595);
    expect(route.coordinates.first.longitude, 126.8526);
  });

  test('haversine distance is symmetric and bounded', () {
    final first = distanceMeters(
      firstLatitude: 35.1595,
      firstLongitude: 126.8526,
      secondLatitude: 35.1605,
      secondLongitude: 126.8536,
    );
    final reverse = distanceMeters(
      firstLatitude: 35.1605,
      firstLongitude: 126.8536,
      secondLatitude: 35.1595,
      secondLongitude: 126.8526,
    );

    expect(first, closeTo(reverse, 0.001));
    expect(first, inInclusiveRange(130, 160));
  });
}
