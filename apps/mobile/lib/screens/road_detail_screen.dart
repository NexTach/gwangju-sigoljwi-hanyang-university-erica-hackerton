import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../state/providers.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';

class RoadDetailScreen extends ConsumerWidget {
  const RoadDetailScreen({
    required this.roadSegmentId,
    this.fallbackName,
    this.seed,
    super.key,
  });

  final String? fallbackName;
  final String roadSegmentId;
  final RoadMapItem? seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(roadDetailProvider(roadSegmentId));
    final isDemoRoad = roadSegmentId.startsWith('demo-');
    final detail = isDemoRoad ? null : detailState.value;
    final seedRoad = isDemoRoad ? null : seed;
    final wheelchairScore = detail?.scores
        .where((score) => score.movementType == MovementType.wheelchair)
        .firstOrNull;
    final score =
        (isDemoRoad ? 41 : null) ??
        seedRoad?.score ??
        wheelchairScore?.score ??
        65;
    final eventCount =
        (isDemoRoad ? 5 : null) ??
        detail?.eventCount ??
        seedRoad?.eventCount ??
        (score < 60 ? 5 : 12);
    final confidence =
        (isDemoRoad ? 0.65 : null) ??
        wheelchairScore?.confidence ??
        seedRoad?.confidence ??
        0.65;
    final roadName =
        (isDemoRoad ? fallbackName : null) ??
        detail?.roadName ??
        seedRoad?.roadName ??
        fallbackName ??
        '오크가 & 3번길 구간';
    final isCaution = score < 60;
    final scoreColor = isCaution
        ? CompanionColors.red
        : score < 75
        ? CompanionColors.amber
        : CompanionColors.green;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roadName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Road Segment #${_shortId(roadSegmentId)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    CompanionCard(
                      padding: const EdgeInsets.all(22),
                      radius: 28,
                      child: Row(
                        children: [
                          CompanionScoreRing(
                            color: scoreColor,
                            score: score,
                            size: 88,
                            strokeWidth: 9,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCaution ? '이동 장애 가능 구간' : '이동하기 편안한 구간',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: scoreColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '휠체어 기준 · ${isCaution ? '반복적인 충격 감지' : '안정적인 노면 감지'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    CompanionCard(
                      padding: const EdgeInsets.all(19),
                      radius: 24,
                      child: Column(
                        children: [
                          _RoadMetricBar(
                            color: scoreColor,
                            label: '노면 상태',
                            value: isDemoRoad ? 38 : score.clamp(0, 100),
                          ),
                          const SizedBox(height: 14),
                          _RoadMetricBar(
                            color: CompanionColors.amberBright,
                            label: '경사도',
                            value: (score + 23).clamp(0, 100),
                          ),
                          const SizedBox(height: 14),
                          _RoadMetricBar(
                            color: isCaution
                                ? CompanionColors.red
                                : CompanionColors.greenBright,
                            label: '반복 진동',
                            value: isCaution ? 21 : 78,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    CompanionCard(
                      color: CompanionColors.creamMuted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 15,
                      ),
                      radius: 20,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 45,
                            child: Stack(
                              children: const [
                                CircleAvatar(
                                  backgroundColor: CompanionColors.coral,
                                  radius: 11,
                                ),
                                Positioned(
                                  left: 12,
                                  child: CircleAvatar(
                                    backgroundColor:
                                        CompanionColors.amberBright,
                                    radius: 11,
                                  ),
                                ),
                                Positioned(
                                  left: 24,
                                  child: CircleAvatar(
                                    backgroundColor:
                                        CompanionColors.greenBright,
                                    radius: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              '신뢰도 ${(confidence * 100).round()}% · $eventCount건의 이동 데이터로 계산됐어요',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: CompanionColors.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isDemoRoad && detailState.hasError) ...[
                      const SizedBox(height: 10),
                      CompanionCard(
                        color: CompanionColors.amberSoft,
                        padding: const EdgeInsets.all(13),
                        radius: 17,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud_off_outlined,
                              color: CompanionColors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                '최신 정보를 불러오지 못해 저장된 분석을 보여드려요.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              onPressed: () => ref.invalidate(
                                roadDetailProvider(roadSegmentId),
                              ),
                              tooltip: '다시 불러오기',
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      '최근 감지 기록',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 9),
                    _DetectionRow(
                      color: isCaution
                          ? CompanionColors.red
                          : CompanionColors.green,
                      label: isCaution ? '강한 단일 충격 감지' : '평탄한 노면 패턴 감지',
                      time: '2시간 전',
                    ),
                    const SizedBox(height: 9),
                    const _DetectionRow(
                      color: CompanionColors.amberBright,
                      label: '반복적인 진동 패턴 감지',
                      time: '어제',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CompanionPrimaryButton(
                label: isCaution ? '이 구간 피해서 안내받기' : '이 구간으로 안내받기',
                onPressed: () {
                  showCompanionMessage(
                    context,
                    isCaution
                        ? '이 구간을 피하는 경로를 준비할게요.'
                        : '이 구간을 포함한 편안한 경로를 준비할게요.',
                  );
                  context.push('/movement');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortId(String value) {
    final digits = value.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length >= 3) return digits.substring(digits.length - 3);
    return digits.isEmpty ? '132' : digits;
  }
}

class _RoadMetricBar extends StatelessWidget {
  const _RoadMetricBar({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const Spacer(),
          Text('$value / 100', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
      const SizedBox(height: 7),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          backgroundColor: CompanionColors.creamMuted,
          color: color,
          minHeight: 8,
          value: value / 100,
        ),
      ),
    ],
  );
}

class _DetectionRow extends StatelessWidget {
  const _DetectionRow({
    required this.color,
    required this.label,
    required this.time,
  });

  final Color color;
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) => CompanionCard(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    radius: 16,
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(time, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}
