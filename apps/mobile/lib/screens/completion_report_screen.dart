import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/tracking_controller.dart';
import '../ui/companion_map.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_report_state.dart';

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
    final distanceMeters = result.distanceMeters > 20
        ? result.distanceMeters
        : 2200;
    final movement = result.movementType?.label ?? '휠체어';
    final report =
        selectedReport ??
        WalkReport(
          date: '오늘',
          distanceKilometers: distanceMeters / 1000,
          durationMinutes: 26,
          id: 'pending-report',
          movementLabel: movement,
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
          score: result.acceptedEvents > 2 ? 82 : 88,
          summary: '대체로 편안한 경로였어요',
        );

    void finish() {
      final reportsController = ref.read(demoWalkReportsProvider.notifier);
      if (selectedReport == null) {
        reportsController.saveCompletedWalk(
          acceptedEvents: result.acceptedEvents,
          distanceMeters: result.distanceMeters,
          movementLabel: movement,
        );
      } else {
        reportsController.save(report);
      }
      ref.read(trackingProvider.notifier).reset();
      context.go('/home');
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
              const CompanionMapArtwork(
                height: 154,
                showLabels: false,
                style: CompanionMapStyle.report,
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
                      onPressed: () =>
                          showCompanionMessage(context, '산책 리포트 공유 링크를 준비했어요.'),
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CompanionPrimaryButton(
                      label: '경로 저장',
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
