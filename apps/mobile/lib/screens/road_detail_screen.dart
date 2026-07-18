import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../state/providers.dart';
import '../state/tracking_controller.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';

class RoadDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<RoadDetailScreen> createState() => _RoadDetailScreenState();
}

class _RoadDetailScreenState extends ConsumerState<RoadDetailScreen> {
  bool _preparingRoute = false;

  @override
  Widget build(BuildContext context) {
    final roadSegmentId = widget.roadSegmentId;
    final detailState = ref.watch(roadDetailProvider(roadSegmentId));
    final isDemoRoad = roadSegmentId.startsWith('demo-');
    final detail = isDemoRoad ? null : detailState.value;
    final seedRoad = isDemoRoad ? null : widget.seed;
    final wheelchairScore = detail?.scores
        .where((score) => score.movementType == MovementType.wheelchair)
        .firstOrNull;
    final demoMetrics = _demoMetrics(roadSegmentId);
    final score =
        demoMetrics?.score ?? seedRoad?.score ?? wheelchairScore?.score ?? 65;
    final eventCount =
        demoMetrics?.eventCount ??
        detail?.eventCount ??
        seedRoad?.eventCount ??
        (score < 60 ? 5 : 12);
    final confidence =
        demoMetrics?.confidence ??
        wheelchairScore?.confidence ??
        seedRoad?.confidence ??
        0.65;
    final roadName =
        (isDemoRoad ? widget.fallbackName : null) ??
        detail?.roadName ??
        seedRoad?.roadName ??
        widget.fallbackName ??
        '오크가 & 3번길 구간';
    final isBarrier = score < 60;
    final needsCaution = score < 75;
    final scoreColor = isBarrier
        ? CompanionColors.red
        : needsCaution
        ? CompanionColors.amber
        : CompanionColors.green;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompanionBackLink(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              const SizedBox(height: 4),
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
                                  isBarrier
                                      ? '이동 장애 가능 구간'
                                      : needsCaution
                                      ? '주의가 필요한 구간'
                                      : '이동하기 편안한 구간',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: scoreColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '휠체어 기준 · ${needsCaution ? '반복적인 충격 감지' : '안정적인 노면 감지'}',
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
                            value: demoMetrics?.surface ?? score.clamp(0, 100),
                          ),
                          const SizedBox(height: 14),
                          _RoadMetricBar(
                            color: CompanionColors.amberBright,
                            label: '경사도',
                            value:
                                demoMetrics?.slope ??
                                (score + 23).clamp(0, 100),
                          ),
                          const SizedBox(height: 14),
                          _RoadMetricBar(
                            color: needsCaution
                                ? CompanionColors.red
                                : CompanionColors.greenBright,
                            label: '반복 진동',
                            value:
                                demoMetrics?.vibration ??
                                (needsCaution ? 21 : 78),
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
                      color: needsCaution
                          ? CompanionColors.red
                          : CompanionColors.green,
                      label: needsCaution ? '강한 단일 충격 감지' : '평탄한 노면 패턴 감지',
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
                label: needsCaution ? '이 구간 피해서 안내받기' : '이 구간으로 안내받기',
                loading: _preparingRoute,
                onPressed: () => _prepareGuidance(
                  needsCaution: needsCaution,
                  roadName: roadName,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _prepareGuidance({
    required bool needsCaution,
    required String roadName,
  }) async {
    if (_preparingRoute) return;
    setState(() => _preparingRoute = true);

    final tracking = ref.read(trackingProvider);
    final movement =
        tracking.movementType ?? ref.read(demoProfileProvider).movementType;

    if (tracking.status == TrackingStatus.active) {
      await ref.read(trackingProvider.notifier).stop();
      if (!mounted) return;
      ref.read(trackingProvider.notifier).reset();
    }

    if (!mounted) return;
    final queryParameters = <String, String>{
      'movement': movement.apiName,
      if (needsCaution) 'avoidRoad': widget.roadSegmentId,
      if (needsCaution) 'avoidName': roadName,
    };
    context.go(
      Uri(path: '/routes', queryParameters: queryParameters).toString(),
    );
  }

  String _shortId(String value) {
    final digits = value.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length >= 3) return digits.substring(digits.length - 3);
    return digits.isEmpty ? '132' : digits;
  }

  _DemoRoadMetrics? _demoMetrics(String value) => switch (value) {
    'demo-101' => const _DemoRoadMetrics(
      confidence: 0.82,
      eventCount: 9,
      score: 92,
      slope: 88,
      surface: 94,
      vibration: 92,
    ),
    'demo-204' => const _DemoRoadMetrics(
      confidence: 0.78,
      eventCount: 7,
      score: 88,
      slope: 84,
      surface: 90,
      vibration: 89,
    ),
    'demo-245' => const _DemoRoadMetrics(
      confidence: 0.58,
      eventCount: 4,
      score: 64,
      slope: 72,
      surface: 62,
      vibration: 58,
    ),
    _ when value.startsWith('demo-') => const _DemoRoadMetrics(
      confidence: 0.65,
      eventCount: 5,
      score: 41,
      slope: 64,
      surface: 38,
      vibration: 21,
    ),
    _ => null,
  };
}

class _DemoRoadMetrics {
  const _DemoRoadMetrics({
    required this.confidence,
    required this.eventCount,
    required this.score,
    required this.slope,
    required this.surface,
    required this.vibration,
  });

  final double confidence;
  final int eventCount;
  final int score;
  final int slope;
  final int surface;
  final int vibration;
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
