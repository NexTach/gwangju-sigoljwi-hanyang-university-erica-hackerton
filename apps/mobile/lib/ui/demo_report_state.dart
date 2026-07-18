import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WalkReportRecordTone { warning, positive }

@immutable
class WalkReportRecord {
  const WalkReportRecord({required this.text, required this.tone});

  final String text;
  final WalkReportRecordTone tone;
}

@immutable
class WalkReport {
  const WalkReport({
    required this.date,
    required this.distanceKilometers,
    required this.durationMinutes,
    required this.id,
    required this.movementLabel,
    required this.place,
    required this.records,
    required this.score,
    required this.summary,
  });

  final String date;
  final double distanceKilometers;
  final int durationMinutes;
  final String id;
  final String movementLabel;
  final String place;
  final List<WalkReportRecord> records;
  final int score;
  final String summary;

  String get distanceLabel => '${distanceKilometers.toStringAsFixed(1)}km';

  String get durationLabel => '$durationMinutes분';
}

class DemoWalkReportsController extends Notifier<List<WalkReport>> {
  var _nextSavedId = 1;

  @override
  List<WalkReport> build() {
    _nextSavedId = 1;
    return const [
      WalkReport(
        date: '오늘',
        distanceKilometers: 2.2,
        durationMinutes: 26,
        id: 'report-today',
        movementLabel: '휠체어',
        place: '용봉로 · 전남대학교 방면',
        records: [
          WalkReportRecord(
            text: '오크가의 경사로 없는 연석을 피해 안내했어요',
            tone: WalkReportRecordTone.warning,
          ),
          WalkReportRecord(
            text: '1km의 평탄한 보도를 지났어요',
            tone: WalkReportRecordTone.positive,
          ),
        ],
        score: 88,
        summary: '대체로 편안한 경로였어요',
      ),
      WalkReport(
        date: '어제',
        distanceKilometers: 1.4,
        durationMinutes: 19,
        id: 'report-yesterday',
        movementLabel: '휠체어',
        place: '오크가 · 3번길 구간',
        records: [
          WalkReportRecord(
            text: '연석 단차가 있는 구간에서 속도를 낮췄어요',
            tone: WalkReportRecordTone.warning,
          ),
          WalkReportRecord(
            text: '완만한 경사 구간을 안전하게 지났어요',
            tone: WalkReportRecordTone.positive,
          ),
        ],
        score: 64,
        summary: '일부 구간에서 주의가 필요했어요',
      ),
      WalkReport(
        date: '3일 전',
        distanceKilometers: 3.1,
        durationMinutes: 38,
        id: 'report-riverside',
        movementLabel: '유모차',
        place: '리버사이드길',
        records: [
          WalkReportRecord(
            text: '강변 진입로의 짧은 경사를 안내했어요',
            tone: WalkReportRecordTone.warning,
          ),
          WalkReportRecord(
            text: '2km 넘게 평탄한 보도를 지났어요',
            tone: WalkReportRecordTone.positive,
          ),
        ],
        score: 93,
        summary: '매우 편안하고 평탄한 경로였어요',
      ),
      WalkReport(
        date: '5일 전',
        distanceKilometers: 1.8,
        durationMinutes: 24,
        id: 'report-construction',
        movementLabel: '휠체어',
        place: '메인가 · 공사 구간 우회',
        records: [
          WalkReportRecord(
            text: '공사 중인 좁은 보도를 피해 안내했어요',
            tone: WalkReportRecordTone.warning,
          ),
          WalkReportRecord(
            text: '우회로의 낮은 경사로를 이용했어요',
            tone: WalkReportRecordTone.positive,
          ),
        ],
        score: 47,
        summary: '공사 구간을 피해 조심해서 이동했어요',
      ),
    ];
  }

  WalkReport saveCompletedWalk({
    required int acceptedEvents,
    required double distanceMeters,
    required String movementLabel,
  }) {
    final normalizedDistance = distanceMeters > 20 ? distanceMeters : 2200;
    final report = WalkReport(
      date: '오늘',
      distanceKilometers: normalizedDistance / 1000,
      durationMinutes: 26,
      id: 'saved-report-${_nextSavedId++}',
      movementLabel: movementLabel,
      place: '용봉로 · 방금 걸은 경로',
      records: const [
        WalkReportRecord(
          text: '오크가의 경사로 없는 연석을 피해 안내했어요',
          tone: WalkReportRecordTone.warning,
        ),
        WalkReportRecord(
          text: '1km의 평탄한 보도를 지났어요',
          tone: WalkReportRecordTone.positive,
        ),
      ],
      score: acceptedEvents > 2 ? 82 : 88,
      summary: '대체로 편안한 경로였어요',
    );
    save(report);
    return report;
  }

  void save(WalkReport report) {
    state = [
      report,
      for (final saved in state)
        if (saved.id != report.id) saved,
    ];
  }
}

final demoWalkReportsProvider =
    NotifierProvider<DemoWalkReportsController, List<WalkReport>>(
      DemoWalkReportsController.new,
    );
