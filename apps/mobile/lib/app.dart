import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:road_dna_design/road_dna_design.dart';

import 'core/models.dart';
import 'screens/community_screen.dart';
import 'screens/community_write_screen.dart';
import 'screens/completion_report_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/movement_selection_screen.dart';
import 'screens/nearby_screen.dart';
import 'screens/nickname_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_settings_screens.dart';
import 'screens/road_detail_screen.dart';
import 'screens/route_comparison_screen.dart';
import 'screens/sensor_analysis_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/walk_reports_screen.dart';
import 'ui/companion_theme.dart';
import 'ui/companion_widgets.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    errorBuilder: (context, state) => Scaffold(
      body: RdEmptyState(
        action: RdButton(label: '홈으로 이동', onPressed: () => context.go('/home')),
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
      GoRoute(builder: (context, state) => const LoginScreen(), path: '/login'),
      GoRoute(
        builder: (context, state) => const PermissionScreen(),
        path: '/permission',
      ),
      GoRoute(builder: (context, state) => const TermsScreen(), path: '/terms'),
      GoRoute(
        builder: (context, state) => const NicknameScreen(),
        path: '/nickname',
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder:
            (context, navigationShell, branchNavigators) => CompanionTabShell(
              branchNavigators: branchNavigators,
              navigationShell: navigationShell,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                builder: (context, state) => const NearbyScreen(),
                path: '/nearby',
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                builder: (context, state) => const CommunityScreen(),
                path: '/community',
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                builder: (context, state) => const HomeScreen(),
                path: '/home',
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                builder: (context, state) => const WalkReportsScreen(),
                path: '/reports',
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                builder: (context, state) => const ProfileScreen(),
                path: '/profile',
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        builder: (context, state) => const CommunityWriteScreen(),
        path: '/community/write',
      ),
      GoRoute(
        builder: (context, state) => const NotificationsScreen(),
        path: '/notifications',
      ),
      GoRoute(
        builder: (context, state) => const MovementSelectionScreen(),
        path: '/movement',
      ),
      GoRoute(
        builder: (context, state) => const TrackingScreen(),
        path: '/tracking',
      ),
      GoRoute(
        builder: (context, state) => const CompletionReportScreen(),
        path: '/report',
      ),
      GoRoute(
        builder: (context, state) => const SensorAnalysisScreen(),
        path: '/sensor',
      ),
      GoRoute(
        builder: (context, state) => const ProfileEditScreen(),
        path: '/profile/edit',
      ),
      GoRoute(
        builder: (context, state) => const AccessibilitySettingsScreen(),
        path: '/profile/accessibility',
      ),
      GoRoute(
        builder: (context, state) => const NotificationSettingsScreen(),
        path: '/profile/notifications',
      ),
      GoRoute(
        builder: (context, state) => const PrivacyTermsScreen(),
        path: '/profile/privacy',
      ),
      GoRoute(
        builder: (context, state) => const SupportScreen(),
        path: '/profile/support',
      ),
      GoRoute(
        builder: (context, state) => const AppInfoScreen(),
        path: '/profile/about',
      ),
      GoRoute(
        builder: (context, state) {
          final value = state.uri.queryParameters['movement'];
          final movement = MovementType.values.firstWhere(
            (movement) => movement.apiName == value,
            orElse: () => MovementType.wheelchair,
          );
          return RouteComparisonScreen(
            avoidedRoadName: state.uri.queryParameters['avoidName'],
            avoidedRoadSegmentId: state.uri.queryParameters['avoidRoad'],
            initialMovement: movement,
            targetRoadName: state.uri.queryParameters['targetName'],
            targetRoadSegmentId: state.uri.queryParameters['targetRoad'],
          );
        },
        path: '/routes',
      ),
      GoRoute(
        builder: (context, state) {
          final extra = state.extra;
          return RoadDetailScreen(
            fallbackName: state.uri.queryParameters['name'],
            roadSegmentId: state.pathParameters['id']!,
            seed: extra is RoadMapItem ? extra : null,
          );
        },
        path: '/road/:id',
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
    theme: companionTheme(),
    themeMode: ThemeMode.light,
    title: 'Road DNA',
  );
}
