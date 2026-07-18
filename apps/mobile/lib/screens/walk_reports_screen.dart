import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_report_state.dart';

class WalkReportsScreen extends ConsumerWidget {
  const WalkReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(demoWalkReportsProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '산책 리포트',
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                '지금까지의 산책 기록이에요',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: CompanionColors.muted),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: reports.length,
                  itemBuilder: (context, index) =>
                      _ReportCard(report: reports[index]),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final WalkReport report;

  @override
  Widget build(BuildContext context) => CompanionCard(
    onTap: () => context.push(
      Uri(path: '/report', queryParameters: {'id': report.id}).toString(),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    radius: 22,
    semanticLabel: '${report.place} 산책 리포트 보기',
    child: Row(
      children: [
        _CompactScoreRing(
          score: report.score,
          color: _scoreColor(report.score),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.place,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${report.date} · ${report.distanceLabel} · ${report.durationLabel}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: CompanionColors.faint,
          size: 18,
        ),
      ],
    ),
  );

  Color _scoreColor(int score) {
    if (score >= 75) return CompanionColors.greenBright;
    if (score >= 55) return CompanionColors.amberBright;
    return const Color(0xFFE14F3D);
  }
}

class _CompactScoreRing extends StatelessWidget {
  const _CompactScoreRing({required this.color, required this.score});

  final Color color;
  final int score;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '산책 점수 $score점',
    child: SizedBox.square(
      dimension: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 46,
            child: CircularProgressIndicator(
              backgroundColor: CompanionColors.creamMuted,
              color: color,
              strokeCap: StrokeCap.round,
              strokeWidth: 6,
              value: score / 100,
            ),
          ),
          Text(
            '$score',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
