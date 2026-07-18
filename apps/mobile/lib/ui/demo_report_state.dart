import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo/yongbong_demo_data.dart';
import '../services/walk_report_storage.dart';

enum WalkReportRecordTone { warning, positive }

String formatWalkDistance(double distanceKilometers) {
  final safeKilometers = distanceKilometers.isFinite
      ? distanceKilometers.clamp(0, double.infinity).toDouble()
      : 0.0;
  final meters = (safeKilometers * 1000).round().clamp(0, 999999999);
  if (meters < 1000) return '${meters}m';
  return '${safeKilometers.toStringAsFixed(1)}km';
}

@immutable
class WalkReportRecord {
  const WalkReportRecord({required this.text, required this.tone});

  final String text;
  final WalkReportRecordTone tone;

  factory WalkReportRecord.fromJson(Map<String, dynamic> json) =>
      WalkReportRecord(
        text: json['text'] as String? ?? '',
        tone: WalkReportRecordTone.values.firstWhere(
          (tone) => tone.name == json['tone'],
          orElse: () => WalkReportRecordTone.positive,
        ),
      );

  Map<String, Object> toJson() => {'text': text, 'tone': tone.name};
}

@immutable
class WalkReportImpact {
  const WalkReportImpact({
    required this.detectedAt,
    required this.impactLevel,
    required this.latitude,
    required this.longitude,
    required this.severity,
    this.roadSegmentId,
  });

  factory WalkReportImpact.fromJson(Map<String, dynamic> json) =>
      WalkReportImpact(
        detectedAt: json['detectedAt'] as String? ?? '',
        impactLevel: json['impactLevel'] as String? ?? '충격',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        roadSegmentId: json['roadSegmentId'] as String?,
        severity: (json['severity'] as num?)?.toDouble() ?? 0,
      );

  final String detectedAt;
  final String impactLevel;
  final double latitude;
  final double longitude;
  final String? roadSegmentId;
  final double severity;

  Map<String, Object?> toJson() => {
    'detectedAt': detectedAt,
    'impactLevel': impactLevel,
    'latitude': latitude,
    'longitude': longitude,
    'roadSegmentId': roadSegmentId,
    'severity': severity,
  };
}

@immutable
class WalkReport {
  const WalkReport({
    required this.date,
    required this.distanceKilometers,
    required this.durationMinutes,
    this.durationSeconds,
    this.endedAt,
    required this.id,
    this.impacts = const [],
    required this.movementLabel,
    required this.place,
    required this.records,
    required this.score,
    this.startedAt,
    required this.summary,
    this.routeCoordinates = const [],
  });

  final String date;
  final double distanceKilometers;
  final int durationMinutes;
  final int? durationSeconds;
  final DateTime? endedAt;
  final String id;
  final List<WalkReportImpact> impacts;
  final String movementLabel;
  final String place;
  final List<WalkReportRecord> records;
  final List<({double latitude, double longitude})> routeCoordinates;
  final int score;
  final DateTime? startedAt;
  final String summary;

  String get distanceLabel => formatWalkDistance(distanceKilometers);

  String get durationLabel {
    final measuredSeconds = durationSeconds;
    if (measuredSeconds == null) return '$durationMinutes분';
    final seconds = measuredSeconds < 0 ? 0 : measuredSeconds;
    if (seconds < 60) return '$seconds초';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) return '$minutes분';
    return '$minutes분 $remainingSeconds초';
  }

  String get distanceRecordText => '$distanceLabel의 이동 경로를 기록했어요';

  WalkReport copyWith({String? id}) => WalkReport(
    date: date,
    distanceKilometers: distanceKilometers,
    durationMinutes: durationMinutes,
    durationSeconds: durationSeconds,
    endedAt: endedAt,
    id: id ?? this.id,
    impacts: impacts,
    movementLabel: movementLabel,
    place: place,
    records: records,
    routeCoordinates: routeCoordinates,
    score: score,
    startedAt: startedAt,
    summary: summary,
  );

  String get shareText {
    final impactLine = impacts.isEmpty
        ? '충격 기록 없음'
        : '충격 발생 지점 ${impacts.length}곳 기록';
    return [
      'Road DNA · $date의 산책 리포트',
      summary,
      place,
      '$distanceLabel · $durationLabel · $movementLabel 모드',
      impactLine,
    ].join('\n');
  }

  factory WalkReport.fromJson(Map<String, dynamic> json) {
    final recordsJson = json['records'];
    final routeJson = json['routeCoordinates'];
    final impactsJson = json['impacts'];
    return WalkReport(
      date: json['date'] as String? ?? '오늘',
      distanceKilometers: (json['distanceKilometers'] as num?)?.toDouble() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      endedAt: _tryParseDateTime(json['endedAt']),
      id: json['id'] as String? ?? '',
      impacts: [
        if (impactsJson is List)
          for (final impact in impactsJson)
            if (impact is Map)
              WalkReportImpact.fromJson(Map<String, dynamic>.from(impact)),
      ],
      movementLabel: json['movementLabel'] as String? ?? '휠체어',
      place: json['place'] as String? ?? '용봉동',
      records: [
        if (recordsJson is List)
          for (final record in recordsJson)
            if (record is Map)
              WalkReportRecord.fromJson(Map<String, dynamic>.from(record)),
      ],
      routeCoordinates: [
        if (routeJson is List)
          for (final coordinate in routeJson)
            if (coordinate is Map &&
                coordinate['latitude'] is num &&
                coordinate['longitude'] is num)
              (
                latitude: (coordinate['latitude'] as num).toDouble(),
                longitude: (coordinate['longitude'] as num).toDouble(),
              ),
      ],
      score: (json['score'] as num?)?.toInt() ?? 0,
      startedAt: _tryParseDateTime(json['startedAt']),
      summary: json['summary'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'date': date,
    'distanceKilometers': distanceKilometers,
    'durationMinutes': durationMinutes,
    'durationSeconds': durationSeconds,
    'endedAt': endedAt?.toUtc().toIso8601String(),
    'id': id,
    'impacts': [for (final impact in impacts) impact.toJson()],
    'movementLabel': movementLabel,
    'place': place,
    'records': [for (final record in records) record.toJson()],
    'routeCoordinates': [
      for (final coordinate in routeCoordinates)
        {'latitude': coordinate.latitude, 'longitude': coordinate.longitude},
    ],
    'score': score,
    'startedAt': startedAt?.toUtc().toIso8601String(),
    'summary': summary,
  };
}

DateTime? _tryParseDateTime(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

class DemoWalkReportsController extends Notifier<List<WalkReport>> {
  bool _disposed = false;
  var _nextSavedId = 1;
  Future<void>? _restoreOperation;

  @override
  List<WalkReport> build() {
    _disposed = false;
    _nextSavedId = 1;
    _restoreOperation = null;
    ref.onDispose(() => _disposed = true);
    unawaited(Future<void>.microtask(restore));
    return const [
      WalkReport(
        date: '오늘',
        distanceKilometers: 2.2,
        durationMinutes: 26,
        id: 'report-today',
        impacts: [
          WalkReportImpact(
            detectedAt: '2026-07-19T06:14:12.000Z',
            impactLevel: '중간 충격',
            latitude: 35.179274,
            longitude: 126.899934,
            roadSegmentId: '10000000-0000-4000-8000-000000000132',
            severity: 0.67,
          ),
        ],
        movementLabel: '휠체어',
        place: '반룡로 · 전남대 서문 방면',
        records: [
          WalkReportRecord(
            text: '반룡로의 단차가 감지된 구간을 피해 안내했어요',
            tone: WalkReportRecordTone.warning,
          ),
          WalkReportRecord(
            text: '민주대로의 평탄한 보도를 지났어요',
            tone: WalkReportRecordTone.positive,
          ),
        ],
        routeCoordinates: YongbongDemoData.accessibleRoute,
        score: 88,
        summary: '대체로 편안한 경로였어요',
      ),
      WalkReport(
        date: '어제',
        distanceKilometers: 1.4,
        durationMinutes: 19,
        id: 'report-yesterday',
        impacts: [
          WalkReportImpact(
            detectedAt: '2026-07-18T07:05:33.000Z',
            impactLevel: '높은 충격',
            latitude: 35.177852,
            longitude: 126.899513,
            roadSegmentId: '10000000-0000-4000-8000-000000000204',
            severity: 0.84,
          ),
        ],
        movementLabel: '휠체어',
        place: '설죽로202번길',
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
        routeCoordinates: YongbongDemoData.fastestRoute,
        score: 64,
        summary: '일부 구간에서 주의가 필요했어요',
      ),
      WalkReport(
        date: '3일 전',
        distanceKilometers: 3.1,
        durationMinutes: 38,
        id: 'report-riverside',
        impacts: [
          WalkReportImpact(
            detectedAt: '2026-07-16T04:18:10.000Z',
            impactLevel: '낮은 충격',
            latitude: 35.181270,
            longitude: 126.901541,
            roadSegmentId: '10000000-0000-4000-8000-000000000245',
            severity: 0.34,
          ),
        ],
        movementLabel: '유모차',
        place: '민주대로',
        records: [
          WalkReportRecord(
            text: '캠퍼스 진입부의 짧은 경사를 안내했어요',
            tone: WalkReportRecordTone.warning,
          ),
          WalkReportRecord(
            text: '2km 넘게 평탄한 보도를 지났어요',
            tone: WalkReportRecordTone.positive,
          ),
        ],
        routeCoordinates: YongbongDemoData.accessibleRoute,
        score: 93,
        summary: '매우 편안하고 평탄한 경로였어요',
      ),
      WalkReport(
        date: '5일 전',
        distanceKilometers: 1.8,
        durationMinutes: 24,
        id: 'report-construction',
        impacts: [
          WalkReportImpact(
            detectedAt: '2026-07-14T08:22:41.000Z',
            impactLevel: '높은 충격',
            latitude: 35.180786,
            longitude: 126.900351,
            roadSegmentId: '10000000-0000-4000-8000-000000000132',
            severity: 0.91,
          ),
        ],
        movementLabel: '휠체어',
        place: '고운로 · 공사 구간 우회',
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
        routeCoordinates: YongbongDemoData.fastestRoute,
        score: 47,
        summary: '공사 구간을 피해 조심해서 이동했어요',
      ),
    ];
  }

  Future<void> restore() => _restoreOperation ??= _restorePersistedReports();

  Future<WalkReport> saveCompletedWalk({
    required int acceptedEvents,
    required double distanceMeters,
    int durationSeconds = 0,
    DateTime? endedAt,
    List<WalkReportImpact> impacts = const [],
    required String movementLabel,
    List<({double latitude, double longitude})> routeCoordinates = const [],
    DateTime? startedAt,
  }) async {
    await restore();
    final normalizedDistance = distanceMeters.isFinite
        ? distanceMeters.clamp(0, double.infinity).toDouble()
        : 0.0;
    final normalizedDuration = durationSeconds < 0 ? 0 : durationSeconds;
    final pending = WalkReport(
      date: '오늘',
      distanceKilometers: normalizedDistance / 1000,
      durationMinutes: normalizedDuration ~/ 60,
      durationSeconds: normalizedDuration,
      endedAt: endedAt,
      id: 'saved-report-${_nextSavedId++}',
      impacts: List.unmodifiable(impacts),
      movementLabel: movementLabel,
      place: '용봉동 · 방금 걸은 경로',
      records: [
        WalkReportRecord(
          text: impacts.isEmpty
              ? '이동 중 큰 충격 없이 경로를 마쳤어요'
              : '이동 충격 ${impacts.length}건과 발생 지점을 기록했어요',
          tone: impacts.isEmpty
              ? WalkReportRecordTone.positive
              : WalkReportRecordTone.warning,
        ),
      ],
      routeCoordinates: routeCoordinates.isEmpty
          ? YongbongDemoData.accessibleRoute
          : List.unmodifiable(routeCoordinates),
      score: acceptedEvents > 2 ? 82 : 88,
      startedAt: startedAt,
      summary: '대체로 편안한 경로였어요',
    );
    final report = WalkReport(
      date: pending.date,
      distanceKilometers: pending.distanceKilometers,
      durationMinutes: pending.durationMinutes,
      durationSeconds: pending.durationSeconds,
      endedAt: pending.endedAt,
      id: pending.id,
      impacts: pending.impacts,
      movementLabel: pending.movementLabel,
      place: pending.place,
      records: [
        ...pending.records,
        WalkReportRecord(
          text: pending.distanceRecordText,
          tone: WalkReportRecordTone.positive,
        ),
      ],
      routeCoordinates: pending.routeCoordinates,
      score: pending.score,
      startedAt: pending.startedAt,
      summary: pending.summary,
    );
    await save(report);
    return report;
  }

  Future<WalkReport> saveNew(WalkReport report) async {
    await restore();
    final saved = report.copyWith(id: 'saved-report-${_nextSavedId++}');
    await save(saved);
    return saved;
  }

  Future<void> save(WalkReport report) async {
    await restore();
    final nextReports = [
      report,
      for (final saved in state)
        if (saved.id != report.id) saved,
    ];
    if (!_disposed) {
      state = nextReports;
      _synchronizeNextSavedId(nextReports);
    }
    try {
      await ref
          .read(walkReportStorageProvider)
          .write(
            jsonEncode({
              'version': 1,
              'reports': [for (final saved in nextReports) saved.toJson()],
            }),
          );
    } catch (_) {
      // Keep the report available for this session if device storage is down.
    }
  }

  Future<void> _restorePersistedReports() async {
    if (_disposed) return;
    try {
      final encoded = await ref.read(walkReportStorageProvider).read();
      if (encoded == null || encoded.isEmpty || _disposed) return;
      final decoded = jsonDecode(encoded);
      if (decoded is! Map || decoded['reports'] is! List) return;
      final restored = [
        for (final value in decoded['reports'] as List)
          if (value is Map)
            WalkReport.fromJson(Map<String, dynamic>.from(value)),
      ].where((report) => report.id.isNotEmpty).toList(growable: false);
      if (restored.isEmpty || _disposed) return;
      state = restored;
      _synchronizeNextSavedId(restored);
    } catch (_) {
      // Corrupt or unavailable local data must not block the built-in reports.
    }
  }

  void _synchronizeNextSavedId(List<WalkReport> reports) {
    var nextId = 1;
    for (final report in reports) {
      final match = RegExp(r'^saved-report-(\d+)$').firstMatch(report.id);
      final value = int.tryParse(match?.group(1) ?? '');
      if (value != null && value >= nextId) nextId = value + 1;
    }
    _nextSavedId = nextId;
  }
}

final demoWalkReportsProvider =
    NotifierProvider<DemoWalkReportsController, List<WalkReport>>(
      DemoWalkReportsController.new,
    );
