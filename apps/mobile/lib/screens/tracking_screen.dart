import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:road_dna_design/road_dna_design.dart';

import '../core/models.dart';
import '../state/providers.dart';
import '../state/tracking_controller.dart';
import '../ui/road_map_view.dart';

class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingProvider);
    final config = ref.watch(appConfigProvider);
    final location = tracking.latestLocation;
    final latitude = location?.latitude ?? 35.15995;
    final longitude = location?.longitude ?? 126.85315;
    final movement = tracking.movementType;
    final List<RoadMapItem> roads = movement == null
        ? const []
        : ref
                  .watch(
                    nearbyRoadsProvider(
                      NearbyRoadRequest(
                        latitude: (latitude * 10000).round() / 10000,
                        longitude: (longitude * 10000).round() / 10000,
                        movementType: movement,
                      ),
                    ),
                  )
                  .value ??
              const [];

    ref.listen<int>(
      trackingProvider.select((state) => state.feedbackSequence),
      (previous, next) {
        if (next <= (previous ?? 0)) return;
        final candidate = ref.read(trackingProvider).lastCandidate;
        showRdToast(
          context,
          message: candidate?.isPossibleDrop == true
              ? '큰 단발 충격을 휴대폰 낙하 가능성으로 보류했어요'
              : '이동 충격 패턴을 감지했어요',
          tone: RdFeedbackTone.warning,
        );
      },
    );

    if (tracking.status == TrackingStatus.idle ||
        tracking.status == TrackingStatus.failure) {
      return Scaffold(
        appBar: RdNavigation(
          onBack: () => context.go('/home'),
          title: '측정 준비',
        ),
        body: RdEmptyState(
          action: RdButton(
            label: '홈으로 돌아가기',
            onPressed: () => context.go('/home'),
          ),
          description: tracking.errorMessage ?? '활성 측정 세션이 없어요.',
          icon: Icons.sensors_off_rounded,
          title: '측정을 시작할 수 없어요',
        ),
      );
    }

    final recentImpact =
        tracking.lastCandidate != null &&
        DateTime.now().toUtc().difference(tracking.lastCandidate!.detectedAt) <
            const Duration(seconds: 3);
    final ribbonState = recentImpact
        ? RdRoadScanState.impact
        : tracking.status == TrackingStatus.active
        ? RdRoadScanState.active
        : RdRoadScanState.idle;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: RdNavigation(
          actions: [
            if (config.demoMode)
              const Padding(
                padding: EdgeInsets.only(right: RdSpacing.x2),
                child: RdBadge(
                  dot: true,
                  label: '데모 센서',
                  tone: RdBadgeTone.info,
                ),
              ),
          ],
          subtitle: movement?.label,
          title: '도로 분석 중',
        ),
        bottomNavigationBar: _TrackingBottomPanel(
          state: tracking,
          onStop: () => _stop(context, ref),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: RoadMapView(
                barriers: tracking.barriers,
                center: LatLng(latitude, longitude),
                currentLocation: location,
                roads: roads,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(RdSpacing.x3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RdRoadScanRibbon(state: ribbonState),
                    const SizedBox(height: RdSpacing.x2),
                    if (tracking.errorMessage != null)
                      RdAlert(
                        message: tracking.errorMessage!,
                        title: '측정 상태를 확인해 주세요',
                        tone: RdFeedbackTone.warning,
                      ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: RdSurface(
                        tone: RdSurfaceTone.elevated,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.gps_fixed_rounded,
                              color: location != null && location.accuracy <= 25
                                  ? context.rdColors.statusSuccess
                                  : context.rdColors.statusWarning,
                              size: 18,
                            ),
                            const SizedBox(width: RdSpacing.x2),
                            Text(
                              location == null
                                  ? 'GPS 확인 중'
                                  : 'GPS ±${location.accuracy.toStringAsFixed(0)}m',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _stop(BuildContext context, WidgetRef ref) async {
    await ref.read(trackingProvider.notifier).stop();
    if (!context.mounted) return;
    final result = ref.read(trackingProvider);
    await showRdBottomSheet<void>(
      context: context,
      semanticLabel: '측정 완료',
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          RdSpacing.x5,
          RdSpacing.x2,
          RdSpacing.x5,
          RdSpacing.x5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: sheetContext.rdColors.statusSuccess,
              size: 48,
            ),
            const SizedBox(height: RdSpacing.x4),
            Text(
              '이동이 도시 데이터가 됐어요',
              style: Theme.of(sheetContext).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RdSpacing.x2),
            Text(
              '원본 센서 신호는 전송하지 않았고, 수용된 충격 후보와 도로 구간만 집계했어요.',
              style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                color: sheetContext.rdColors.contentSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RdSpacing.x6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                RdMetric(
                  label: '이동 거리',
                  value: '${result.distanceMeters.toStringAsFixed(0)}m',
                ),
                RdMetric(
                  label: '수용 후보',
                  value: '${result.acceptedEvents}건',
                ),
                RdMetric(label: '보류', value: '${result.heldEvents}건'),
              ],
            ),
            if (result.errorMessage != null) ...[
              const SizedBox(height: RdSpacing.x4),
              RdAlert(
                message: result.errorMessage!,
                title: '동기화 안내',
                tone: RdFeedbackTone.warning,
              ),
            ],
            const SizedBox(height: RdSpacing.x6),
            RdButton(
              fullWidth: true,
              label: '지도로 돌아가기',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                ref.read(trackingProvider.notifier).reset();
                context.go('/home');
              },
              size: RdButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingBottomPanel extends StatelessWidget {
  const _TrackingBottomPanel({
    required this.onStop,
    required this.state,
  });

  final VoidCallback onStop;
  final TrackingState state;

  @override
  Widget build(BuildContext context) => RdBottomCta(
    description:
        '센서 ${state.lastSensorMagnitude.toStringAsFixed(1)} m/s² · 보류 ${state.heldEvents}건',
    primary: RdButton(
      fullWidth: true,
      label: '측정 종료',
      loading: state.status == TrackingStatus.stopping,
      onPressed: state.status == TrackingStatus.active ? onStop : null,
      size: RdButtonSize.large,
      tone: RdButtonTone.danger,
    ),
    secondary: Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          RdMetric(
            label: '이동',
            value: '${state.distanceMeters.toStringAsFixed(0)}m',
          ),
          RdMetric(label: '후보', value: '${state.acceptedEvents}'),
        ],
      ),
    ),
  );
}
