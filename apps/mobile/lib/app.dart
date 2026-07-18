import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:road_dna_design/road_dna_design.dart';

import 'core/models.dart';
import 'design_system_catalog.dart';
import 'screens/debug_calibration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/route_comparison_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tracking_screen.dart';
import 'state/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);
  return GoRouter(
    errorBuilder: (context, state) => Scaffold(
      body: RdEmptyState(
        action: RdButton(
          label: '홈으로 이동',
          onPressed: () => context.go('/home'),
        ),
        description: '요청한 화면 ${state.uri.path}을 찾을 수 없어요.',
        icon: Icons.explore_off_rounded,
        title: '화면을 찾을 수 없어요',
      ),
    ),
    initialLocation: '/splash',
    routes: [
      GoRoute(
        builder: (context, state) => const SplashScreen(),
        path: '/splash',
      ),
      GoRoute(
        builder: (context, state) => const PermissionScreen(),
        path: '/permission',
      ),
      GoRoute(
        builder: (context, state) => const HomeScreen(),
        path: '/home',
      ),
      GoRoute(
        builder: (context, state) => const TrackingScreen(),
        path: '/tracking',
      ),
      GoRoute(
        builder: (context, state) {
          final value = state.uri.queryParameters['movement'];
          final movement = MovementType.values.firstWhere(
            (movement) => movement.apiName == value,
            orElse: () => MovementType.wheelchair,
          );
          return RouteComparisonScreen(initialMovement: movement);
        },
        path: '/routes',
      ),
      GoRoute(
        builder: (context, state) => const DebugCalibrationScreen(),
        redirect: (context, state) =>
            kDebugMode || config.demoMode ? null : '/home',
        path: '/debug',
      ),
      GoRoute(
        builder: (context, state) => const _CatalogScreen(),
        redirect: (context, state) =>
            kDebugMode || config.demoMode ? null : '/home',
        path: '/design-system',
      ),
    ],
  );
});

class RoadDnaApp extends ConsumerWidget {
  const RoadDnaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    darkTheme: RdTheme.dark(),
    debugShowCheckedModeBanner: false,
    routerConfig: ref.watch(routerProvider),
    theme: RdTheme.light(),
    themeMode: ref.watch(themeModeProvider),
    title: 'Road DNA',
  );
}

class _CatalogScreen extends ConsumerWidget {
  const _CatalogScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) => DesignSystemCatalog(
    darkMode: Theme.of(context).brightness == Brightness.dark,
    onDarkModeChanged: (_) => ref
        .read(themeModeProvider.notifier)
        .toggle(Theme.of(context).brightness),
  );
}
