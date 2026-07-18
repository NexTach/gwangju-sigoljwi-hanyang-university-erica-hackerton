import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../state/providers.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';

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
    final location = ref.watch(currentLocationProvider).value;
    final latitude = location?.latitude ?? 35.15995;
    final longitude = location?.longitude ?? 126.85315;
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
    final allItems = config.demoMode
        ? _demoNearbyItems
        : roads == null || roads.isEmpty
        ? const <_NearbyItem>[]
        : [
            for (final (index, road) in roads.indexed)
              _NearbyItem.fromRoad(road, index),
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
      bottomNavigationBar: const CompanionBottomNav(
        current: CompanionTab.nearby,
      ),
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
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        '이 조건에 맞는 주변 구간이 없어요.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _NearbyCard(item: item);
                      },
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                    ),
            ),
          ],
        ),
      ),
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
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? CompanionColors.white : CompanionColors.ink,
            ),
          ),
        ),
      ),
    ),
  );
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.item});

  final _NearbyItem item;

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
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      radius: 22,
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

  factory _NearbyItem.fromRoad(RoadMapItem road, int index) => _NearbyItem(
    distance: '${120 + index * 85}m',
    grade: road.grade,
    id: road.roadSegmentId,
    location: '광주 북구 용봉동',
    road: road,
    tag: switch (road.grade) {
      RoadGrade.good => '매우 편안',
      RoadGrade.normal => '편안',
      RoadGrade.caution => '주의',
      RoadGrade.poor => '불편',
      RoadGrade.unknown => '분석 중',
    },
    title: road.roadName,
  );

  final String distance;
  final RoadGrade grade;
  final String id;
  final String location;
  final RoadMapItem? road;
  final String tag;
  final String title;
}

const _demoNearbyItems = [
  _NearbyItem(
    distance: '0.2km',
    grade: RoadGrade.good,
    id: 'demo-101',
    location: '메이플로',
    tag: '편안',
    title: '평탄하고 안전한 구간',
  ),
  _NearbyItem(
    distance: '0.4km',
    grade: RoadGrade.poor,
    id: 'demo-132',
    location: '오크가 & 3번길',
    tag: '이동 장애 가능',
    title: '반복적인 충격이 감지됐어요',
  ),
  _NearbyItem(
    distance: '0.6km',
    grade: RoadGrade.normal,
    id: 'demo-204',
    location: '리버사이드길',
    tag: '편안',
    title: '완만하고 평평한 경로',
  ),
  _NearbyItem(
    distance: '0.9km',
    grade: RoadGrade.caution,
    id: 'demo-245',
    location: '메인가',
    tag: '주의',
    title: '노면 진동이 다소 있어요',
  ),
];
