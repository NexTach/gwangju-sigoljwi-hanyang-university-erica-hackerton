import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/tracking_controller.dart';
import '../ui/companion_map.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

class CompletionReportScreen extends ConsumerWidget {
  const CompletionReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(trackingProvider);
    final distance = result.distanceMeters > 20 ? result.distanceMeters : 2200;
    final events = result.acceptedEvents;
    final score = events > 2 ? 82 : 88;
    final movement = result.movementType?.label ?? '휠체어';

    void finish() {
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
              Text(
                '산책 잘 하셨어요',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '오늘의 산책 리포트예요',
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
                    CompanionScoreRing(score: score, size: 80),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '대체로 편안한 경로였어요',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: CompanionColors.green),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(distance / 1000).toStringAsFixed(1)}km · 26분 · $movement 모드',
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
              Text('오늘의 기록', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 9),
              const _ReportRecord(
                backgroundColor: CompanionColors.amberSoft,
                color: CompanionColors.amber,
                icon: Icons.error_outline_rounded,
                text: '오크가의 경사로 없는 연석을 피해 안내했어요',
              ),
              const SizedBox(height: 9),
              const _ReportRecord(
                backgroundColor: CompanionColors.greenSoft,
                color: CompanionColors.green,
                icon: Icons.check_rounded,
                text: '1km의 평탄한 보도를 지났어요',
              ),
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
}

class _ReportRecord extends StatelessWidget {
  const _ReportRecord({
    required this.backgroundColor,
    required this.color,
    required this.icon,
    required this.text,
  });

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
