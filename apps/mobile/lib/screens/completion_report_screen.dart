import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../core/geo.dart' as geo;
import '../services/report_share_service.dart';
import '../state/tracking_controller.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_report_state.dart';
import '../ui/road_map_view.dart';

class CompletionReportScreen extends ConsumerWidget {
  const CompletionReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(trackingProvider);
    final reports = ref.watch(demoWalkReportsProvider);
    final selectedId = GoRouterState.of(context).uri.queryParameters['id'];
    WalkReport? selectedReport;
    for (final report in reports) {
      if (report.id == selectedId) {
        selectedReport = report;
        break;
      }
    }
    final report = selectedReport ?? buildCompletedWalkReport(result);
    final reportTrace = [
      for (final coordinate in report.routeCoordinates)
        LatLng(coordinate.latitude, coordinate.longitude),
    ];
    final reportImpactPoints = [
      for (final impact in report.impacts)
        LatLng(impact.latitude, impact.longitude),
    ];

    Future<void> finish() async {
      try {
        if (selectedReport == null) {
          await ref.read(demoWalkReportsProvider.notifier).saveNew(report);
        }
        ref.read(trackingProvider.notifier).reset();
        if (context.mounted) context.go('/home');
      } catch (_) {
        if (context.mounted) {
          showCompanionMessage(context, '경로를 저장하지 못했어요. 잠시 후 다시 시도해 주세요.');
        }
      }
    }

    Future<void> share() async {
      try {
        await ref.read(reportShareServiceProvider).share(report);
      } catch (_) {
        if (context.mounted) {
          showCompanionMessage(context, '공유 화면을 열지 못했어요. 잠시 후 다시 시도해 주세요.');
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompanionBackLink(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              Text(
                '산책 잘 하셨어요',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${report.date}의 산책 리포트예요',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: CompanionColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              CompanionCard(
                padding: const EdgeInsets.all(20),
                radius: 28,
                child: Row(
                  children: [
                    CompanionScoreRing(
                      color: _scoreColor(report.score),
                      score: report.score,
                      size: 80,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.summary,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: _scoreTextColor(report.score),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: CompanionColors.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${report.distanceLabel} · ${report.durationLabel} · ${report.movementLabel} 모드',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SizedBox(
                  height: 154,
                  child: RoadMapView(
                    center: reportTrace.isEmpty
                        ? roadDnaFallbackCenter
                        : reportTrace.first,
                    fitPadding: const EdgeInsets.all(22),
                    fitToContent: true,
                    impactPoints: reportImpactPoints,
                    trace: reportTrace,
                    traceColor: CompanionColors.greenBright,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${report.date}의 기록',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 9),
              for (var index = 0; index < report.records.length; index++) ...[
                _ReportRecord.fromReport(report.records[index]),
                if (index != report.records.length - 1)
                  const SizedBox(height: 9),
              ],
              if (result.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  result.errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: CompanionColors.red),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: CompanionPrimaryButton(
                      foregroundColor: CompanionColors.ink,
                      label: '공유하기',
                      onPressed: share,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CompanionPrimaryButton(
                      label: selectedReport == null ? '경로 저장' : '완료',
                      onPressed: finish,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return CompanionColors.greenBright;
    if (score >= 55) return CompanionColors.amberBright;
    return const Color(0xFFE14F3D);
  }

  Color _scoreTextColor(int score) {
    if (score >= 75) return CompanionColors.green;
    if (score >= 55) return CompanionColors.amber;
    return CompanionColors.red;
  }
}

WalkReport buildCompletedWalkReport(TrackingState result) {
  final measuredMeters = _measuredDistanceMeters(result);
  final startedAt = result.session?.startedAt ?? _firstTraceTime(result);
  final endedAt = _lastTrackingTime(result);
  final durationSeconds = _durationSecondsBetween(startedAt, endedAt);
  final routeCoordinates = [
    for (final location in result.routeTrace)
      (latitude: location.latitude, longitude: location.longitude),
  ];
  final reportCoordinates = routeCoordinates.isNotEmpty
      ? routeCoordinates
      : result.selectedRoute?.coordinates ?? const [];
  final impacts = [
    for (final barrier in result.barriers)
      WalkReportImpact(
        detectedAt: barrier.candidate.detectedAt.toUtc().toIso8601String(),
        impactLevel: barrier.candidate.impactLevel.label,
        latitude: barrier.location.latitude,
        longitude: barrier.location.longitude,
        roadSegmentId: barrier.roadSegmentId,
        severity: barrier.candidate.severity,
      ),
  ];
  final distanceLabel = formatWalkDistance(measuredMeters / 1000);
  return WalkReport(
    date: '오늘',
    distanceKilometers: measuredMeters / 1000,
    durationMinutes: durationSeconds ~/ 60,
    durationSeconds: durationSeconds,
    endedAt: endedAt,
    id: 'pending-report',
    impacts: impacts,
    movementLabel: result.movementType?.label ?? '휠체어',
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
      WalkReportRecord(
        text: '$distanceLabel의 이동 경로를 기록했어요',
        tone: WalkReportRecordTone.positive,
      ),
    ],
    routeCoordinates: reportCoordinates,
    score: result.acceptedEvents > 2 ? 82 : 88,
    startedAt: startedAt,
    summary: '대체로 편안한 경로였어요',
  );
}

double _measuredDistanceMeters(TrackingState result) {
  final accumulated = result.distanceMeters;
  if (accumulated.isFinite && accumulated > 0) return accumulated;
  var measured = 0.0;
  for (var index = 1; index < result.routeTrace.length; index++) {
    final previous = result.routeTrace[index - 1];
    final current = result.routeTrace[index];
    final segment = geo.distanceMeters(
      firstLatitude: previous.latitude,
      firstLongitude: previous.longitude,
      secondLatitude: current.latitude,
      secondLongitude: current.longitude,
    );
    if (segment.isFinite && segment > 0) measured += segment;
  }
  return measured;
}

DateTime? _firstTraceTime(TrackingState result) =>
    result.routeTrace.isEmpty ? null : result.routeTrace.first.recordedAt;

DateTime? _lastTrackingTime(TrackingState result) {
  DateTime? latest;
  void include(DateTime? value) {
    if (value != null && (latest == null || value.isAfter(latest!))) {
      latest = value;
    }
  }

  include(result.latestLocation?.recordedAt);
  if (result.routeTrace.isNotEmpty) {
    include(result.routeTrace.last.recordedAt);
  }
  for (final barrier in result.barriers) {
    include(barrier.candidate.detectedAt);
  }
  return latest;
}

int _durationSecondsBetween(DateTime? startedAt, DateTime? endedAt) {
  if (startedAt == null || endedAt == null || endedAt.isBefore(startedAt)) {
    return 0;
  }
  return endedAt.difference(startedAt).inSeconds;
}

class _ReportRecord extends StatelessWidget {
  const _ReportRecord({
    required this.backgroundColor,
    required this.color,
    required this.icon,
    required this.text,
  });

  factory _ReportRecord.fromReport(WalkReportRecord record) {
    final isWarning = record.tone == WalkReportRecordTone.warning;
    return _ReportRecord(
      backgroundColor: isWarning
          ? CompanionColors.amberSoft
          : CompanionColors.greenSoft,
      color: isWarning ? CompanionColors.amber : CompanionColors.green,
      icon: isWarning ? Icons.error_outline_rounded : Icons.check_rounded,
      text: record.text,
    );
  }

  final Color backgroundColor;
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => CompanionCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    radius: 19,
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 36,
            child: Icon(icon, color: color, size: 17),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}
