import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models.dart';
import '../state/providers.dart';
import '../state/tracking_controller.dart';
import '../ui/companion_theme.dart';
import '../ui/companion_widgets.dart';
import '../ui/demo_profile_state.dart';

class RouteComparisonScreen extends ConsumerStatefulWidget {
  const RouteComparisonScreen({required this.initialMovement, super.key});

  final MovementType initialMovement;

  @override
  ConsumerState<RouteComparisonScreen> createState() =>
      _RouteComparisonScreenState();
}

class _RouteComparisonScreenState extends ConsumerState<RouteComparisonScreen> {
  late Future<RouteComparison> _comparison;
  late MovementType _movement;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _movement = widget.initialMovement;
    _comparison = _fetchComparison(_movement);
  }

  Future<RouteComparison> _fetchComparison(MovementType movement) async {
    LocationReading current;
    final cached = ref.read(currentLocationProvider).value;
    if (cached != null) {
      current = cached;
    } else {
      try {
        current = await ref.read(locationServiceProvider).current();
      } catch (_) {
        current = LocationReading(
          accuracy: 999,
          latitude: 35.15958,
          longitude: 126.85261,
          recordedAt: DateTime.now().toUtc(),
          speed: 0,
        );
      }
    }
    return ref
        .read(apiProvider)
        .compareRoutes(
          destinationLatitude: current.latitude + 0.0041,
          destinationLongitude: current.longitude + 0.0047,
          movementType: movement,
          originLatitude: current.latitude,
          originLongitude: current.longitude,
        );
  }

  void _reload() {
    final selectedMovement = _movement;
    setState(() => _comparison = _fetchComparison(selectedMovement));
  }

  Future<void> _startTracking() async {
    ref.read(demoProfileProvider.notifier).setMovementType(_movement);
    setState(() => _starting = true);
    final started = await ref.read(trackingProvider.notifier).start(_movement);
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
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CompanionScreenHeader(
              subtitle: '전남대학교 후문 · ${_movementLabel(_movement)} 모드',
              title: '경로를 비교해보세요',
            ),
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
                              style: Theme.of(context).textTheme.headlineSmall,
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
                  final accessible = comparison.routes.firstWhere(
                    (route) => route.type == RouteType.accessible,
                    orElse: () => comparison.routes.last,
                  );
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _RouteCard(route: fastest),
                      const SizedBox(height: 14),
                      _RouteCard(route: accessible, recommended: true),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            CompanionPrimaryButton(
              label: '안전한 경로로 출발',
              loading: _starting,
              onPressed: _startTracking,
            ),
          ],
        ),
      ),
    ),
  );

  String _movementLabel(MovementType movement) => switch (movement) {
    MovementType.wheelchair => '휠체어',
    MovementType.stroller => '유모차',
    MovementType.walking => '보행',
  };
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route, this.recommended = false});

  final bool recommended;
  final RouteOption route;

  @override
  Widget build(BuildContext context) {
    final score = route.accessibilityScore;
    final safe = recommended || (score ?? 0) >= 70;
    return CompanionCard(
      border: recommended ? CompanionColors.greenBright : null,
      padding: const EdgeInsets.all(20),
      radius: 24,
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
                    Text(
                      recommended ? 'Road DNA 추천' : '빠른 길',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    if (recommended)
                      const CompanionTag(
                        label: 'AI 추천',
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
