import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../core/models.dart';
import '../state/providers.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';
import '../ui/road_map_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final profile = ref.watch(demoProfileProvider);
    final location = ref.watch(currentLocationProvider).value;
    final latitude = location?.latitude ?? roadDnaFallbackCenter.latitude;
    final longitude = location?.longitude ?? roadDnaFallbackCenter.longitude;
    final mapCenter = LatLng(latitude, longitude);
    final roads = ref.watch(
      nearbyRoadsProvider(
        NearbyRoadRequest(
          latitude: (latitude * 10000).round() / 10000,
          longitude: (longitude * 10000).round() / 10000,
          movementType: profile.movementType,
        ),
      ),
    );
    final contribution = ref.watch(contributionProvider).value;
    final roadItems = roads.value ?? const <RoadMapItem>[];
    final availableScores = roadItems
        .where((road) => road.score != null)
        .map((road) => road.score!)
        .toList(growable: false);
    final score = config.demoMode
        ? 92
        : availableScores.isEmpty
        ? 92
        : (availableScores.reduce((a, b) => a + b) / availableScores.length)
              .round();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '좋은 오후예요',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CompanionColors.muted,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${profile.nickname}님',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                ),
                CompanionIconButton(
                  icon: Icons.notifications_none_rounded,
                  onPressed: () => context.push('/notifications'),
                  semanticLabel: '알림 보기',
                  size: 48,
                ),
              ],
            ),
            const SizedBox(height: 20),
            CompanionCard(
              color: CompanionColors.coralAction,
              onTap: () => context.push(
                '/routes?movement=${profile.movementType.apiName}',
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              radius: 28,
              semanticLabel: '산책 시작하기',
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: CompanionColors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(
                      dimension: 56,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: CompanionColors.white,
                        size: 29,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '산책 시작하기',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: CompanionColors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'AI 도우미가 함께 안내해드려요',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: CompanionColors.white.withValues(
                                  alpha: 0.88,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: CompanionColors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CompanionCard(
              radius: 28,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CompanionScoreRing(score: score),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROAD DNA SCORE',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: CompanionColors.greenBright,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          score >= 75 ? '오늘은 이동하기 좋아요' : '주의해서 이동해 주세요',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: score >= 75
                                    ? CompanionColors.green
                                    : CompanionColors.amber,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '평탄함 · 경사 낮음 · 최근 ${214 + (contribution?.acceptedEvents ?? 0)}건 데이터 기반',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    height: 190,
                    child: RoadMapView(
                      center: mapCenter,
                      currentLocation: location,
                      fitPadding: const EdgeInsets.fromLTRB(24, 44, 24, 34),
                      fitToContent: true,
                      followCurrentLocation: true,
                      mapController: _mapController,
                      onMapReady: () => _mapReady = true,
                      onRoadTap: _openRoad,
                      roads: roadItems,
                    ),
                  ),
                ),
                const Positioned(
                  left: 14,
                  top: 14,
                  child: CompanionTag(
                    backgroundColor: CompanionColors.white,
                    foregroundColor: CompanionColors.ink,
                    label: '광주 북구 · 용봉동',
                  ),
                ),
                if (roadItems.isNotEmpty)
                  Positioned(
                    bottom: 32,
                    left: 14,
                    child: CompanionTag(
                      backgroundColor: CompanionColors.white,
                      foregroundColor: CompanionColors.green,
                      icon: Icons.route_rounded,
                      label: '근처에 확인할 구간 ${roadItems.length}개',
                    ),
                  ),
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: CompanionIconButton(
                    icon: Icons.my_location_rounded,
                    onPressed: () => _recenter(location),
                    semanticLabel: '현재 위치로 이동',
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openRoad(RoadMapItem road) {
    context.push('/road/${road.roadSegmentId}', extra: road);
  }

  void _recenter(LocationReading? location) {
    if (location == null || !_mapReady) {
      showCompanionMessage(context, '현재 위치를 확인하고 있어요.');
      return;
    }
    _mapController.move(LatLng(location.latitude, location.longitude), 16);
    showCompanionMessage(context, '현재 위치로 지도를 맞췄어요.');
  }
}
