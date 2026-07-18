import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:road_dna_design/road_dna_design.dart';

import '../core/models.dart';
import '../state/providers.dart';

Future<void> showRoadDetailSheet(
  BuildContext context,
  RoadMapItem road,
) => showRdBottomSheet<void>(
  context: context,
  semanticLabel: '${road.roadName} 상세',
  builder: (context) => _RoadDetailContent(road: road),
);

class _RoadDetailContent extends ConsumerWidget {
  const _RoadDetailContent({required this.road});

  final RoadMapItem road;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(roadDetailProvider(road.roadSegmentId));
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      child: detail.when(
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(
            RdSpacing.x5,
            RdSpacing.x2,
            RdSpacing.x5,
            RdSpacing.x8,
          ),
          children: [
            Text(
              data.roadName,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: RdSpacing.x1),
            Text(
              '누적 감지 ${data.eventCount}건 · ${_relativeTime(data.updatedAt)}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.rdColors.contentTertiary,
              ),
            ),
            const SizedBox(height: RdSpacing.x5),
            for (final score in data.scores) ...[
              RdSurface(
                tone: RdSurfaceTone.subtle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(score.movementType.icon, size: 20),
                        const SizedBox(width: RdSpacing.x2),
                        Expanded(
                          child: Text(
                            score.movementType.label,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        RdBadge(
                          label: score.grade.label,
                          tone: _gradeTone(score.grade),
                        ),
                      ],
                    ),
                    const SizedBox(height: RdSpacing.x4),
                    Row(
                      children: [
                        RdScoreGauge(score: score.score, size: 112),
                        const SizedBox(width: RdSpacing.x5),
                        Expanded(
                          child: Column(
                            children: [
                              RdConfidenceBar(value: score.confidence),
                              const SizedBox(height: RdSpacing.x3),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '이동 충격 후보 ${score.eventCount}건',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color:
                                            context.rdColors.contentSecondary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RdSpacing.x3),
            ],
            const RdAlert(
              message:
                  '휴대폰 센서 기반 MVP 내부 지표이며, 법정 접근성 인증이나 안전 보장을 의미하지 않아요.',
              title: '점수 해석 안내',
            ),
          ],
        ),
        error: (error, stackTrace) => RdEmptyState(
          action: RdButton(
            label: '다시 불러오기',
            onPressed: () => ref.invalidate(
              roadDetailProvider(road.roadSegmentId),
            ),
            tone: RdButtonTone.secondary,
          ),
          description: error.toString(),
          icon: Icons.cloud_off_rounded,
          title: '도로 정보를 불러오지 못했어요',
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(RdSpacing.x5),
          child: Column(
            children: [
              RdSkeleton(height: 32),
              SizedBox(height: RdSpacing.x4),
              RdSkeleton(height: 180),
              SizedBox(height: RdSpacing.x3),
              RdSkeleton(height: 180),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime updatedAt) {
    final difference = DateTime.now().toUtc().difference(updatedAt.toUtc());
    if (difference.inMinutes < 1) return '방금 갱신';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    return '${difference.inDays}일 전';
  }

  RdBadgeTone _gradeTone(RoadGrade grade) => switch (grade) {
    RoadGrade.good => RdBadgeTone.success,
    RoadGrade.normal => RdBadgeTone.info,
    RoadGrade.caution => RdBadgeTone.warning,
    RoadGrade.poor => RdBadgeTone.critical,
    RoadGrade.unknown => RdBadgeTone.neutral,
  };
}
