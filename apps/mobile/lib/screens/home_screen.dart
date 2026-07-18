import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:road_dna_design/road_dna_design.dart';

import '../core/models.dart';
import '../services/location_service.dart';
import '../state/providers.dart';
import '../state/tracking_controller.dart';
import '../ui/road_detail_sheet.dart';
import '../ui/road_map_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  MovementType _movementType = MovementType.wheelchair;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final location = ref.watch(currentLocationProvider).value;
    final access = ref.watch(locationAccessProvider).value;
    final latitude = location?.latitude ?? 35.15995;
    final longitude = location?.longitude ?? 126.85315;
    final roads = ref.watch(
      nearbyRoadsProvider(
        NearbyRoadRequest(
          latitude: (latitude * 10000).round() / 10000,
          longitude: (longitude * 10000).round() / 10000,
          movementType: _movementType,
        ),
      ),
    );
    final contribution = ref.watch(contributionProvider).value;

    return Scaffold(
      appBar: RdNavigation(
        actions: [
          RdIconButton(
            icon: const Icon(Icons.alt_route_rounded),
            onPressed: () => context.push(
              '/routes?movement=${_movementType.apiName}',
            ),
            semanticLabel: '접근성 경로 비교',
          ),
          if (kDebugMode || config.demoMode)
            RdIconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => context.push('/debug'),
              semanticLabel: '센서 보정',
            ),
          RdIconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => ref
                .read(themeModeProvider.notifier)
                .toggle(Theme.of(context).brightness),
            semanticLabel: '화면 테마 전환',
          ),
        ],
        subtitle: '이동의 흔적이 도시의 장벽을 발견하다',
        title: 'Road DNA',
      ),
      bottomNavigationBar: RdBottomCta(
        description: '${_movementType.label} 기준으로 센서를 분석해요.',
        primary: RdButton(
          fullWidth: true,
          label: 'Road DNA 측정 시작',
          leading: const Icon(Icons.sensors_rounded, size: 20),
          onPressed: () => _showMovementSheet(context),
          size: RdButtonSize.large,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: roads.when(
              data: (items) => RoadMapView(
                center: LatLng(latitude, longitude),
                currentLocation: location,
                onRoadTap: (road) => showRoadDetailSheet(context, road),
                roads: items,
              ),
              error: (error, stackTrace) => Stack(
                children: [
                  RoadMapView(
                    center: LatLng(latitude, longitude),
                    currentLocation: location,
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(RdSpacing.x5),
                      child: RdAlert(
                        message: error.toString(),
                        title: '도로 데이터를 불러오지 못했어요',
                        tone: RdFeedbackTone.warning,
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => RoadMapView(
                center: LatLng(latitude, longitude),
                currentLocation: location,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(RdSpacing.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (config.demoMode)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: RdBadge(
                        dot: true,
                        label: '명시적 데모 센서',
                        tone: RdBadgeTone.info,
                      ),
                    ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: RdSurface(
                        tone: RdSurfaceTone.elevated,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _movementType.icon,
                                  color: context.rdColors.actionPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: RdSpacing.x2),
                                Expanded(
                                  child: Text(
                                    '${_movementType.label} 지도',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge,
                                  ),
                                ),
                                RdBadge(
                                  label: roads.value == null
                                      ? '불러오는 중'
                                      : '${roads.value!.length}개 구간',
                                  tone: roads.value?.isNotEmpty == true
                                      ? RdBadgeTone.success
                                      : RdBadgeTone.neutral,
                                ),
                              ],
                            ),
                            const SizedBox(height: RdSpacing.x3),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    contribution == null
                                        ? '기여 기록을 불러오는 중'
                                        : '누적 ${(contribution.distanceMeters / 1000).toStringAsFixed(1)}km · 후보 ${contribution.acceptedEvents}건',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: context
                                              .rdColors
                                              .contentSecondary,
                                        ),
                                  ),
                                ),
                                if (access != LocationAccess.granted)
                                  RdIconButton(
                                    icon: const Icon(
                                      Icons.location_disabled_rounded,
                                    ),
                                    onPressed: () => context.push('/permission'),
                                    semanticLabel: '위치 권한 설정',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMovementSheet(BuildContext parentContext) async {
    var selected = _movementType;
    await showRdBottomSheet<void>(
      context: parentContext,
      semanticLabel: '이동 유형 선택',
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
              Text(
                '어떻게 이동하고 있나요?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: RdSpacing.x2),
              Text(
                '휠체어와 유모차는 휴대폰을 프레임에 단단히 고정해야 신뢰도 높은 신호를 만들 수 있어요.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.rdColors.contentSecondary,
                ),
              ),
              const SizedBox(height: RdSpacing.x5),
              RdSegmentedControl<MovementType>(
                onChanged: (value) => setSheetState(() => selected = value),
                segments: MovementType.values
                    .map(
                      (movement) => RdSegment(
                        description: movement == MovementType.walking
                            ? '별도 분류'
                            : '고정 수집',
                        icon: movement.icon,
                        label: movement.label.replaceAll(' 기여', ''),
                        value: movement,
                      ),
                    )
                    .toList(growable: false),
                value: selected,
              ),
              const SizedBox(height: RdSpacing.x5),
              RdAlert(
                message: selected == MovementType.walking
                    ? '보행 데이터는 휠체어·유모차 점수에 섞이지 않고 별도로 집계해요.'
                    : '주머니나 손에 들고 측정하면 오탐이 늘 수 있어요. 기기에 단단히 고정해 주세요.',
                title: selected == MovementType.walking
                    ? '보행 기여 모드'
                    : '휴대폰 고정 확인',
                tone: RdFeedbackTone.info,
              ),
              const SizedBox(height: RdSpacing.x5),
              RdButton(
                fullWidth: true,
                label: '이 유형으로 측정 시작',
                onPressed: () async {
                  setState(() => _movementType = selected);
                  Navigator.of(sheetContext).pop();
                  final started = await ref
                      .read(trackingProvider.notifier)
                      .start(selected);
                  if (!mounted || !parentContext.mounted) return;
                  if (started) {
                    parentContext.go('/tracking');
                  } else {
                    showRdToast(
                      parentContext,
                      message:
                          ref.read(trackingProvider).errorMessage ??
                          '측정을 시작하지 못했어요.',
                      tone: RdFeedbackTone.critical,
                    );
                  }
                },
                size: RdButtonSize.large,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
