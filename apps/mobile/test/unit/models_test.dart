import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/core/geo.dart';
import 'package:road_dna_mobile/core/models.dart';

void main() {
  group('Describe RoadMapItem.fromJson', () {
    group('Context 분석 전 도로 점수가 null인 경우', () {
      test('It 미확인 점수를 100점과 구분해 보존한다', () {
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
    });
  });

  group('Describe RouteOption.fromJson', () {
    group('Context GeoJSON 경도·위도 좌표를 읽는 경우', () {
      test('It 앱의 위도·경도 레코드 순서로 변환한다', () {
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
    });
  });

  group('Describe distanceMeters', () {
    group('Context 두 GPS 좌표 사이 거리를 계산하는 경우', () {
      test('It 방향과 무관한 미터 단위 거리를 반환한다', () {
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
    });
  });
}
