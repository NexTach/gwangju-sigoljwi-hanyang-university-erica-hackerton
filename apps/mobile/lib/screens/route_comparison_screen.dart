import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../core/models.dart';
import '../demo/yongbong_demo_data.dart';
import '../state/providers.dart';
import '../state/tracking_controller.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';
import '../ui/profile_preferences_state.dart';
import '../ui/road_map_view.dart';

class RouteComparisonScreen extends ConsumerStatefulWidget {
  const RouteComparisonScreen({
    required this.initialMovement,
    this.avoidedRoadName,
    this.avoidedRoadSegmentId,
    this.targetRoadName,
    this.targetRoadSegmentId,
    super.key,
  });

  final String? avoidedRoadName;
  final String? avoidedRoadSegmentId;
  final MovementType initialMovement;
  final String? targetRoadName;
  final String? targetRoadSegmentId;

  @override
  ConsumerState<RouteComparisonScreen> createState() =>
      _RouteComparisonScreenState();
}

class _RouteComparisonScreenState extends ConsumerState<RouteComparisonScreen> {
  late Future<RouteComparison> _comparison;
  late MovementType _movement;
  RouteOption? _selectedRoute;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _movement = widget.initialMovement;
    _comparison = _fetchComparison(_movement);
  }

  Future<RouteComparison> _fetchComparison(MovementType movement) async {
    final config = ref.read(appConfigProvider);
    LocationReading current;
    final cached = ref.read(currentLocationProvider).value;
    if (cached != null) {
      current = cached;
    } else {
      try {
        current = await ref.read(locationServiceProvider).current();
      } catch (_) {
        if (!config.demoMode) rethrow;
        current = LocationReading(
          accuracy: 999,
          latitude: roadDnaFallbackCenter.latitude,
          longitude: roadDnaFallbackCenter.longitude,
          recordedAt: DateTime.now().toUtc(),
          speed: 0,
        );
      }
    }
    final destinationLatitude = config.demoMode
        ? YongbongDemoData.destinationLatitude
        : current.latitude + 0.0041;
    final destinationLongitude = config.demoMode
        ? YongbongDemoData.destinationLongitude
        : current.longitude + 0.0047;
    final comparison = await ref
        .read(apiProvider)
        .compareRoutes(
          destinationLatitude: destinationLatitude,
          destinationLongitude: destinationLongitude,
          movementType: movement,
          originLatitude: current.latitude,
          originLongitude: current.longitude,
        );
    if (config.demoMode) {
      return YongbongDemoData.comparisonFor(
        avoidedRoadSegmentId: widget.avoidedRoadSegmentId,
        targetRoadSegmentId: widget.targetRoadSegmentId,
      );
    }
    return comparison;
  }

  void _reload() {
    final selectedMovement = _movement;
    setState(() {
      _selectedRoute = null;
      _comparison = _fetchComparison(selectedMovement);
    });
  }

  Future<void> _startTracking() async {
    ref.read(demoProfileProvider.notifier).setMovementType(_movement);
    setState(() => _starting = true);
    RouteOption selectedRoute;
    try {
      final comparison = await _comparison;
      selectedRoute = _selectedRoute ?? _preferredRoute(comparison.routes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _starting = false);
      showCompanionMessage(context, '경로를 먼저 다시 계산해 주세요.');
      return;
    }
    final started = await ref
        .read(trackingProvider.notifier)
        .start(_movement, route: selectedRoute);
    if (!mounted) return;
    setState(() => _starting = false);
    if (started) {
      context.go('/tracking');
      return;
    }
    final message = ref.read(trackingProvider).errorMessage ?? '측정을 시작하지 못했어요.';
    showCompanionMessage(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(profilePreferencesProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CompanionBackLink(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              const SizedBox(height: 4),
              CompanionScreenHeader(
                subtitle: widget.avoidedRoadSegmentId != null
                    ? '선택한 위험 구간 제외 · ${_movementLabel(_movement)} 모드'
                    : widget.targetRoadSegmentId != null
                    ? '${widget.targetRoadName ?? '선택 구간'}까지 · ${_movementLabel(_movement)} 모드'
                    : '용봉동 · ${_movementLabel(_movement)} 모드',
                title: widget.targetRoadSegmentId == null
                    ? '경로를 비교해보세요'
                    : '선택한 구간으로 안내할게요',
              ),
              if (widget.avoidedRoadSegmentId != null) ...[
                const SizedBox(height: 14),
                CompanionCard(
                  color: CompanionColors.amberSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  radius: 18,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        color: CompanionColors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${widget.avoidedRoadName ?? '도로 구간 #${_shortRoadId(widget.avoidedRoadSegmentId!)}'} 제외 경로예요',
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
              ],
              const SizedBox(height: 24),
              Expanded(
                child: FutureBuilder<RouteComparison>(
                  future: _comparison,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: CompanionCard(
                          color: CompanionColors.amberSoft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.alt_route_rounded,
                                color: CompanionColors.amber,
                                size: 38,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '경로를 계산하지 못했어요',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                snapshot.error.toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _reload,
                                child: const Text('다시 계산하기'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final comparison = snapshot.data;
                    if (comparison == null) {
                      return const _RouteLoading();
                    }
                    if (comparison.routes.isEmpty) {
                      return Center(
                        child: Text(
                          '비교할 수 있는 경로가 아직 없어요.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    final fastest = comparison.routes.firstWhere(
                      (route) => route.type == RouteType.fastest,
                      orElse: () => comparison.routes.first,
                    );
                    final preferred = _preferredRoute(
                      comparison.routes,
                      preferences: preferences,
                    );
                    final selectedRoute = _selectedRoute ?? preferred;
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            height: 190,
                            child: RoadMapView(
                              center: _routeCenter(comparison.routes),
                              fitPadding: const EdgeInsets.all(28),
                              fitToContent: true,
                              routes: comparison.routes,
                              selectedRoute: selectedRoute,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final (index, route)
                            in comparison.routes.indexed) ...[
                          _RouteCard(
                            onTap: () => setState(() => _selectedRoute = route),
                            recommended: identical(route, preferred),
                            route: route,
                            selected: identical(selectedRoute, route),
                            title:
                                widget.targetRoadSegmentId != null &&
                                    comparison.routes.length == 1
                                ? '${widget.targetRoadName ?? '선택 구간'}까지'
                                : identical(route, fastest)
                                ? '빠른 길'
                                : 'Road DNA 추천',
                          ),
                          if (index != comparison.routes.length - 1)
                            const SizedBox(height: 14),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              CompanionPrimaryButton(
                label: '이 경로로 안내받기',
                loading: _starting,
                onPressed: _startTracking,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _movementLabel(MovementType movement) => switch (movement) {
    MovementType.wheelchair => '휠체어',
    MovementType.stroller => '유모차',
    MovementType.walking => '보행',
  };

  RouteOption _preferredRoute(
    List<RouteOption> routes, {
    ProfilePreferencesState? preferences,
  }) {
    final ProfilePreferencesState profilePreferences =
        preferences ?? ref.read(profilePreferencesProvider);
    final preferAccessible =
        widget.avoidedRoadSegmentId != null ||
        widget.targetRoadSegmentId != null ||
        profilePreferences.avoidStairs ||
        profilePreferences.preferGentleSlopes ||
        profilePreferences.preferSmoothRoads;
    final preferredType = preferAccessible
        ? RouteType.accessible
        : RouteType.fastest;
    for (final route in routes) {
      if (route.type == preferredType) return route;
    }
    return routes.first;
  }

  LatLng _routeCenter(List<RouteOption> routes) {
    final route = routes.first;
    if (route.coordinates.isEmpty) return roadDnaFallbackCenter;
    final coordinate = route.coordinates.first;
    return LatLng(coordinate.latitude, coordinate.longitude);
  }

  String _shortRoadId(String value) {
    final digits = value.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length >= 3) return digits.substring(digits.length - 3);
    return digits.isEmpty ? value : digits;
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.onTap,
    required this.route,
    required this.selected,
    required this.title,
    this.recommended = false,
  });

  final VoidCallback onTap;
  final bool recommended;
  final RouteOption route;
  final bool selected;
  final String title;

  @override
  Widget build(BuildContext context) {
    final score = route.accessibilityScore;
    final safe = (score ?? 0) >= 70;
    return CompanionCard(
      border: selected
          ? (recommended
                ? CompanionColors.greenBright
                : CompanionColors.coralAction)
          : null,
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      radius: 24,
      selected: selected,
      semanticLabel: '$title 선택, ${(route.duration / 60).ceil()}분',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 6,
                  spacing: 8,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    if (recommended)
                      const CompanionTag(
                        label: '설정 추천',
                        backgroundColor: CompanionColors.greenBright,
                        foregroundColor: CompanionColors.white,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CompanionTag(
                backgroundColor: safe
                    ? CompanionColors.greenSoft
                    : CompanionColors.coralSoft,
                foregroundColor: safe
                    ? CompanionColors.green
                    : CompanionColors.red,
                label: '접근성 ${score ?? '—'}',
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${(route.duration / 60).ceil()}분 · ${route.distance}m',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: CompanionColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: CompanionColors.creamMuted),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                safe ? Icons.check_rounded : Icons.error_outline_rounded,
                color: safe ? CompanionColors.green : CompanionColors.red,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  safe ? '평탄한 노면 · 경사 낮음' : '이 구간에서 반복적인 진동이 감지됐어요',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: safe ? CompanionColors.green : CompanionColors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteLoading extends StatelessWidget {
  const _RouteLoading();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < 2; index++) ...[
        Container(
          height: 138,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: CompanionColors.white,
          ),
        ),
        if (index == 0) const SizedBox(height: 14),
      ],
    ],
  );
}
