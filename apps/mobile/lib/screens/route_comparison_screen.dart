import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:road_dna_design/road_dna_design.dart';

import '../core/models.dart';
import '../state/providers.dart';
import '../ui/road_map_view.dart';

class RouteComparisonScreen extends ConsumerStatefulWidget {
  const RouteComparisonScreen({required this.initialMovement, super.key});

  final MovementType initialMovement;

  @override
  ConsumerState<RouteComparisonScreen> createState() =>
      _RouteComparisonScreenState();
}

class _RouteComparisonScreenState
    extends ConsumerState<RouteComparisonScreen> {
  late MovementType _movement;
  Future<RouteComparison>? _comparison;

  @override
  void initState() {
    super.initState();
    _movement = widget.initialMovement;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final current =
        ref.read(currentLocationProvider).value ??
        await ref.read(locationServiceProvider).current().catchError(
          (_) => LocationReading(
            accuracy: 999,
            latitude: 35.15958,
            longitude: 126.85261,
            recordedAt: DateTime.now().toUtc(),
            speed: 0,
          ),
        );
    if (!mounted) return;
    setState(
      () => _comparison = ref
          .read(apiProvider)
          .compareRoutes(
            destinationLatitude: current.latitude + 0.0041,
            destinationLongitude: current.longitude + 0.0047,
            movementType: _movement,
            originLatitude: current.latitude,
            originLongitude: current.longitude,
          ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: RdNavigation(
      onBack: () => context.pop(),
      subtitle: '광주 5·18 기념공원까지',
      title: '접근성 경로 비교',
    ),
    body: FutureBuilder<RouteComparison>(
      future: _comparison,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return RdEmptyState(
            action: RdButton(label: '다시 계산하기', onPressed: _load),
            description: snapshot.error.toString(),
            icon: Icons.alt_route_rounded,
            title: '경로를 계산하지 못했어요',
          );
        }
        final comparison = snapshot.data;
        if (comparison == null) {
          return const Padding(
            padding: EdgeInsets.all(RdSpacing.x5),
            child: Column(
              children: [
                RdSkeleton(height: 320),
                SizedBox(height: RdSpacing.x4),
                RdSkeleton(height: 120),
                SizedBox(height: RdSpacing.x3),
                RdSkeleton(height: 120),
              ],
            ),
          );
        }
        final center = comparison.routes.first.coordinates[
          comparison.routes.first.coordinates.length ~/ 2
        ];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(RdSpacing.x3),
              child: RdSegmentedControl<MovementType>(
                onChanged: (value) {
                  setState(() => _movement = value);
                  _load();
                },
                segments: MovementType.values
                    .map(
                      (movement) => RdSegment(
                        icon: movement.icon,
                        label: movement.label.replaceAll(' 기여', ''),
                        value: movement,
                      ),
                    )
                    .toList(growable: false),
                value: _movement,
              ),
            ),
            SizedBox(
              height: 300,
              child: RoadMapView(
                center: LatLng(center.latitude, center.longitude),
                routes: comparison.routes,
                showAttribution: true,
                zoom: 15,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(RdSpacing.x5),
                children: [
                  for (final route in comparison.routes) ...[
                    _RouteCard(route: route),
                    const SizedBox(height: RdSpacing.x3),
                  ],
                  RdAlert(
                    message: comparison.disclaimer,
                    title: '경로 지표 안내',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});

  final RouteOption route;

  @override
  Widget build(BuildContext context) {
    final isAccessible = route.type == RouteType.accessible;
    return RdSurface(
      tone: isAccessible ? RdSurfaceTone.elevated : RdSurfaceTone.subtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isAccessible
                    ? Icons.accessible_forward_rounded
                    : Icons.bolt_rounded,
                color: isAccessible
                    ? context.rdColors.actionPrimary
                    : context.rdColors.contentSecondary,
              ),
              const SizedBox(width: RdSpacing.x2),
              Expanded(
                child: Text(
                  isAccessible ? 'Road DNA 추천' : '빠른 경로',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              if (isAccessible)
                const RdBadge(
                  label: '이동 편의 우선',
                  tone: RdBadgeTone.info,
                ),
            ],
          ),
          const SizedBox(height: RdSpacing.x4),
          Row(
            children: [
              Expanded(
                child: RdMetric(
                  label: '예상 시간',
                  value: '${(route.duration / 60).ceil()}분',
                ),
              ),
              Expanded(
                child: RdMetric(
                  label: '거리',
                  value: '${route.distance}m',
                ),
              ),
              Expanded(
                child: RdMetric(
                  label: '접근성',
                  value: route.accessibilityScore?.toString() ?? '—',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
