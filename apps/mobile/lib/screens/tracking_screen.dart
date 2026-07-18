import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/tracking_controller.dart';
import '../ui/companion_map.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  bool _assistantPaused = false;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _stop() async {
    await ref.read(trackingProvider.notifier).stop();
    if (!mounted) return;
    context.go('/report');
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);
    final profile = ref.watch(demoProfileProvider);

    ref.listen<int>(
      trackingProvider.select((state) => state.feedbackSequence),
      (previous, next) {
        if (next <= (previous ?? 0)) return;
        final candidate = ref.read(trackingProvider).lastCandidate;
        showCompanionMessage(
          context,
          candidate?.isPossibleDrop == true
              ? '큰 단발 충격을 휴대폰 낙하 가능성으로 보류했어요'
              : '이동 충격 패턴을 감지했어요',
        );
      },
    );

    if (tracking.status == TrackingStatus.idle ||
        tracking.status == TrackingStatus.failure) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CompanionScreenHeader(
                  onBack: () => context.go('/home'),
                  title: '측정 준비',
                ),
                const Spacer(),
                const Icon(
                  Icons.sensors_off_rounded,
                  color: CompanionColors.muted,
                  size: 52,
                ),
                const SizedBox(height: 16),
                Text(
                  '측정을 시작할 수 없어요',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  tracking.errorMessage ?? '활성 측정 세션이 없어요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CompanionColors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                CompanionPrimaryButton(
                  label: '홈으로 돌아가기',
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final elapsed = tracking.session == null
        ? Duration.zero
        : DateTime.now().toUtc().difference(tracking.session!.startedAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds.remainder(60);
    final displayDistance = tracking.distanceMeters > 0
        ? tracking.distanceMeters
        : elapsed.inSeconds * 1.55;
    final latest = tracking.latestLocation;
    final score = tracking.acceptedEvents == 0 ? 96 : 88;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mapHeight = (constraints.maxHeight * 0.45).clamp(
                300.0,
                380.0,
              );
              return Column(
                children: [
                  SizedBox(
                    height: mapHeight,
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: CompanionMapArtwork(
                            height: double.infinity,
                            style: CompanionMapStyle.tracking,
                          ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          top: 16,
                          child: Row(
                            children: [
                              CompanionIconButton(
                                backgroundColor: CompanionColors.white,
                                icon: Icons.menu_rounded,
                                onPressed: () => showCompanionMessage(
                                  context,
                                  '측정을 종료하면 홈 메뉴를 이용할 수 있어요.',
                                ),
                                semanticLabel: '측정 메뉴',
                                size: 40,
                              ),
                              const Spacer(),
                              CompanionTag(
                                backgroundColor: CompanionColors.ink,
                                foregroundColor: CompanionColors.white,
                                label:
                                    '${(displayDistance / 1000).toStringAsFixed(1)}km · $minutes분',
                                icon: Icons.route_rounded,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 20,
                          top: 68,
                          child: Row(
                            children: [
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: CompanionColors.greenBright,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox.square(dimension: 8),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                _assistantPaused ? '안내 일시정지' : '함께 걷는 중',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: CompanionColors.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 20,
                          child: Transform.translate(
                            offset: const Offset(0, 22),
                            child: CompanionIconButton(
                              icon: Icons.my_location_rounded,
                              onPressed: () => showCompanionMessage(
                                context,
                                latest == null
                                    ? 'GPS 신호를 확인하고 있어요.'
                                    : '현재 위치를 중심으로 표시했어요.',
                              ),
                              semanticLabel: '현재 위치',
                              size: 48,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        color: CompanionColors.cream,
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                height: 4,
                                width: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: CompanionColors.creamLine,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '${profile.nickname}님, 함께 걷고 있어요',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 12),
                            CompanionCard(
                              color: CompanionColors.creamMuted,
                              onTap: () => context.push('/sensor'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              radius: 999,
                              semanticLabel: '센서 분석 상세 보기',
                              child: Row(
                                children: [
                                  CompanionScoreRing(score: score, size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '이 구간 점수 $score · ${score >= 90 ? '매우 안전해요' : '주의가 필요해요'}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelMedium,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: CompanionColors.muted,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _TrackingMetric(
                                  icon: Icons.location_on_outlined,
                                  label:
                                      '${(displayDistance / 1000).toStringAsFixed(1)}km',
                                ),
                                const _MetricDivider(),
                                _TrackingMetric(
                                  icon: Icons.schedule_rounded,
                                  label:
                                      '$minutes:${seconds.toString().padLeft(2, '0')}',
                                ),
                                const _MetricDivider(),
                                _TrackingMetric(
                                  icon:
                                      tracking.movementType?.icon ??
                                      Icons.accessible_forward_rounded,
                                  label:
                                      '${tracking.movementType?.label ?? profile.movementType.label} 모드',
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            const Divider(
                              color: CompanionColors.creamMuted,
                              height: 1,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Text(
                                  '산책 도우미',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  icon: Icon(
                                    _assistantPaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.pause_rounded,
                                    size: 17,
                                  ),
                                  label: Text(
                                    _assistantPaused ? '계속하기' : '일시정지',
                                  ),
                                  onPressed: () {
                                    setState(
                                      () =>
                                          _assistantPaused = !_assistantPaused,
                                    );
                                    showCompanionMessage(
                                      context,
                                      _assistantPaused
                                          ? '산책 안내를 일시정지했어요. 도로 분석은 계속돼요.'
                                          : '산책 안내를 다시 시작했어요.',
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: CompanionColors.ink,
                                    textStyle: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.stop_circle_outlined,
                                    size: 17,
                                  ),
                                  label: const Text('종료'),
                                  onPressed:
                                      tracking.status == TrackingStatus.active
                                      ? _stop
                                      : null,
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        CompanionColors.coralAction,
                                    textStyle: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            CompanionCard(
                              color: CompanionColors.amberSoft,
                              onTap: () => context.push(
                                '/road/demo-132?name=오크가%20%26%203번길%20구간',
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 14,
                              ),
                              radius: 20,
                              semanticLabel: '앞쪽 단차 상세 보기',
                              child: Row(
                                children: [
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: CompanionColors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: SizedBox.square(
                                      dimension: 38,
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        color: CompanionColors.amber,
                                        size: 19,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tracking.acceptedEvents > 0
                                              ? '새로운 이동 충격을 감지했어요'
                                              : '40m 앞에 단차가 있어요',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '더 편한 길로 안내해드릴까요?',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: CompanionColors.amber,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TrackingMetric extends StatelessWidget {
  const _TrackingMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: CompanionColors.muted, size: 15),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: CompanionColors.ink),
          ),
        ),
      ],
    ),
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) =>
      Container(color: CompanionColors.creamLine, height: 14, width: 1);
}
