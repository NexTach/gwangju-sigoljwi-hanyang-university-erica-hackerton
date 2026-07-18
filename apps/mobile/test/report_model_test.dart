import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/ui/demo_report_state.dart';

void main() {
  group('Describe formatWalkDistance', () {
    group('Context 이동 거리가 1km 미만이거나 잘못된 값인 경우', () {
      test('It 안전한 미터 단위 문자열을 반환한다', () {
        expect(formatWalkDistance(0.42), '420m');
        expect(formatWalkDistance(-1), '0m');
        expect(formatWalkDistance(double.nan), '0m');
      });
    });

    group('Context 이동 거리가 1km 이상인 경우', () {
      test('It 소수점 한 자리의 km 문자열을 반환한다', () {
        expect(formatWalkDistance(1.26), '1.3km');
      });
    });
  });

  group('Describe WalkReport', () {
    group('Context 측정 시간을 표시하는 경우', () {
      test('It 분과 남은 초를 함께 보존한다', () {
        expect(_report.durationLabel, '1분 35초');
      });
    });

    group('Context 로컬 저장을 위해 JSON 왕복 변환하는 경우', () {
      test('It 시각·경로·충격 정보를 잃지 않는다', () {
        final restored = WalkReport.fromJson(_report.toJson());

        expect(restored.id, _report.id);
        expect(restored.startedAt, _report.startedAt);
        expect(restored.endedAt, _report.endedAt);
        expect(restored.routeCoordinates, _report.routeCoordinates);
        expect(restored.impacts.single.roadSegmentId, 'road-132');
        expect(restored.records.single.tone, WalkReportRecordTone.warning);
      });
    });

    group('Context 공유 문구를 만드는 경우', () {
      test('It 거리·시간·이동 유형과 충격 개수를 포함한다', () {
        expect(_report.shareText, contains('420m · 1분 35초 · 휠체어 모드'));
        expect(_report.shareText, contains('충격 발생 지점 1곳 기록'));
      });
    });
  });
}

final _report = WalkReport(
  date: '오늘',
  distanceKilometers: 0.42,
  durationMinutes: 1,
  durationSeconds: 95,
  endedAt: DateTime.utc(2026, 7, 19, 6, 1, 35),
  id: 'saved-report-1',
  impacts: const [
    WalkReportImpact(
      detectedAt: '2026-07-19T06:00:30.000Z',
      impactLevel: '높은 충격',
      latitude: 35.179274,
      longitude: 126.899934,
      roadSegmentId: 'road-132',
      severity: 0.86,
    ),
  ],
  movementLabel: '휠체어',
  place: '용봉동',
  records: const [
    WalkReportRecord(text: '충격 1건을 기록했어요', tone: WalkReportRecordTone.warning),
  ],
  routeCoordinates: const [
    (latitude: 35.177235, longitude: 126.899021),
    (latitude: 35.179274, longitude: 126.899934),
  ],
  score: 88,
  startedAt: DateTime.utc(2026, 7, 19, 6),
  summary: '대체로 편안한 경로였어요',
);
