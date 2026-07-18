import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../core/geo.dart';
import '../core/models.dart';
import '../demo/yongbong_demo_data.dart';
import '../state/providers.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';
import '../ui/road_map_view.dart';

enum _NearbyFilter { all, comfortable, caution }

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  _NearbyFilter _filter = _NearbyFilter.all;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final profile = ref.watch(demoProfileProvider);
    // The demo GPS deliberately advances every second for the walking
    // experience. Nearby browsing uses the fixed Yongbong area instead so
    // those simulated steps do not replace the map with a new loading state.
    final location = config.demoMode
        ? null
        : ref.watch(currentLocationProvider).value;
    final latitude = location?.latitude ?? YongbongDemoData.centerLatitude;
    final longitude = location?.longitude ?? YongbongDemoData.centerLongitude;
    final roads = ref
        .watch(
          nearbyRoadsProvider(
            NearbyRoadRequest(
              latitude: (latitude * 10000).round() / 10000,
              longitude: (longitude * 10000).round() / 10000,
              movementType: profile.movementType,
            ),
          ),
        )
        .value;
    final allItems = roads == null || roads.isEmpty
        ? const <_NearbyItem>[]
        : [
            for (final road in roads)
              _NearbyItem.fromRoad(
                road,
                originLatitude: latitude,
                originLongitude: longitude,
              ),
          ];
    final items = allItems
        .where((item) {
          return switch (_filter) {
            _NearbyFilter.all => true,
            _NearbyFilter.comfortable =>
              item.grade == RoadGrade.good || item.grade == RoadGrade.normal,
            _NearbyFilter.caution =>
              item.grade == RoadGrade.caution || item.grade == RoadGrade.poor,
          };
        })
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
              child: Text(
                '주변 정보',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: '전체',
                    onTap: () => setState(() => _filter = _NearbyFilter.all),
                    selected: _filter == _NearbyFilter.all,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '편안한 경로',
                    onTap: () =>
                        setState(() => _filter = _NearbyFilter.comfortable),
                    selected: _filter == _NearbyFilter.comfortable,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '주의 구간',
                    onTap: () =>
                        setState(() => _filter = _NearbyFilter.caution),
                    selected: _filter == _NearbyFilter.caution,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (config.demoMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                child: CompanionTag(
                  backgroundColor: CompanionColors.amberSoft,
                  foregroundColor: CompanionColors.amber,
                  label: YongbongDemoData.areaLabel,
                ),
              ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        '이 조건에 맞는 주변 구간이 없어요.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            height: 190,
                            child: RoadMapView(
                              center: config.demoMode
                                  ? const LatLng(
                                      YongbongDemoData.centerLatitude,
                                      YongbongDemoData.centerLongitude,
                                    )
                                  : LatLng(latitude, longitude),
                              onRoadTap: (road) {
                                final item = items
                                    .where(
                                      (item) => item.id == road.roadSegmentId,
                                    )
                                    .firstOrNull;
                                if (item != null) _openRoad(context, item);
                              },
                              roadGeometries: {
                                for (final item in items)
                                  if (YongbongDemoData.roadGeometries[item.id]
                                      case final geometry?)
                                    item.id: [
                                      for (final point in geometry)
                                        LatLng(point.latitude, point.longitude),
                                    ],
                              },
                              roads: items
                                  .map((item) => item.road)
                                  .whereType<RoadMapItem>()
                                  .toList(growable: false),
                              zoom: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '지도나 목록에서 확인할 구간을 눌러보세요',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        for (final (index, item) in items.indexed) ...[
                          _NearbyCard(
                            item: item,
                            onTap: () => _openRoad(context, item),
                          ),
                          if (index != items.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRoad(BuildContext context, _NearbyItem item) {
    context.push(
      Uri(
        path: '/road/${item.id}',
        queryParameters: {'name': '${item.location} 구간'},
      ).toString(),
      extra: item.road,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    required this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    excludeSemantics: true,
    label: '$label 필터',
    selected: selected,
    child: Material(
      borderRadius: BorderRadius.circular(999),
      color: selected ? CompanionColors.ink : CompanionColors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? CompanionColors.white : CompanionColors.ink,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.item, required this.onTap});

  final _NearbyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final comfortable =
        item.grade == RoadGrade.good || item.grade == RoadGrade.normal;
    final severe = item.grade == RoadGrade.poor;
    final color = comfortable
        ? CompanionColors.green
        : severe
        ? CompanionColors.red
        : CompanionColors.amber;
    final background = comfortable
        ? CompanionColors.greenSoft
        : severe
        ? CompanionColors.coralSoft
        : CompanionColors.amberSoft;
    return CompanionCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      radius: 22,
      semanticLabel: '${item.location} 도로 상세 보기',
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(
              dimension: 42,
              child: Icon(
                comfortable ? Icons.check_rounded : Icons.error_outline_rounded,
                color: color,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.location} · ${item.distance}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CompanionTag(
            backgroundColor: background,
            foregroundColor: color,
            label: item.tag,
          ),
        ],
      ),
    );
  }
}

class _NearbyItem {
  const _NearbyItem({
    required this.distance,
    required this.grade,
    required this.id,
    required this.location,
    required this.tag,
    required this.title,
    this.road,
  });

  factory _NearbyItem.fromRoad(
    RoadMapItem road, {
    required double originLatitude,
    required double originLongitude,
  }) {
    final meters = distanceMeters(
      firstLatitude: originLatitude,
      firstLongitude: originLongitude,
      secondLatitude: road.latitude,
      secondLongitude: road.longitude,
    );
    final distanceLabel = meters < 1000
        ? '${meters.round()}m'
        : '${(meters / 1000).toStringAsFixed(1)}km';
    return _NearbyItem(
      distance: distanceLabel,
      grade: road.grade,
      id: road.roadSegmentId,
      location: road.roadName,
      road: road,
      tag: switch (road.grade) {
        RoadGrade.good => '매우 편안',
        RoadGrade.normal => '편안',
        RoadGrade.caution => '주의',
        RoadGrade.poor => '불편',
        RoadGrade.unknown => '분석 중',
      },
      title: road.score == null ? '분석 데이터가 더 필요해요' : '접근성 점수 ${road.score}점',
    );
  }

  final String distance;
  final RoadGrade grade;
  final String id;
  final String location;
  final RoadMapItem? road;
  final String tag;
  final String title;
}
