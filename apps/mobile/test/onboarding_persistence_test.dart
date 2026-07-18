import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:road_dna_mobile/core/models.dart';
import 'package:road_dna_mobile/screens/splash_screen.dart';
import 'package:road_dna_mobile/state/providers.dart';
import 'package:road_dna_mobile/ui/demo_profile_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'completed onboarding restores the nickname and movement type',
    () async {
      SharedPreferences.setMockInitialValues({});
      final firstLaunch = ProviderContainer();
      await firstLaunch.read(demoProfileProvider.notifier).setNickname('새봄이');
      await firstLaunch
          .read(demoProfileProvider.notifier)
          .completeOnboarding(MovementType.stroller);
      firstLaunch.dispose();

      final relaunched = ProviderContainer();
      addTearDown(relaunched.dispose);
      final restored = await relaunched
          .read(demoProfileProvider.notifier)
          .restore();

      expect(restored, isTrue);
      expect(
        relaunched.read(demoProfileProvider),
        isA<DemoProfileState>()
            .having((state) => state.nickname, 'nickname', '새봄이')
            .having(
              (state) => state.movementType,
              'movementType',
              MovementType.stroller,
            )
            .having(
              (state) => state.onboardingCompleted,
              'onboardingCompleted',
              isTrue,
            ),
      );
    },
  );

  test('logout clears the saved onboarding completion', () async {
    SharedPreferences.setMockInitialValues({});
    final signedIn = ProviderContainer();
    await signedIn
        .read(demoProfileProvider.notifier)
        .completeOnboarding(MovementType.walking);
    await signedIn.read(demoProfileProvider.notifier).reset();
    signedIn.dispose();

    final relaunched = ProviderContainer();
    addTearDown(relaunched.dispose);
    final restored = await relaunched
        .read(demoProfileProvider.notifier)
        .restore();

    expect(restored, isFalse);
    expect(
      relaunched.read(demoProfileProvider),
      isA<DemoProfileState>()
          .having((state) => state.nickname, 'nickname', '미나')
          .having(
            (state) => state.movementType,
            'movementType',
            MovementType.wheelchair,
          )
          .having(
            (state) => state.onboardingCompleted,
            'onboardingCompleted',
            isFalse,
          ),
    );
  });

  testWidgets('splash skips to home after onboarding is complete', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final seed = ProviderContainer();
    await seed.read(demoProfileProvider.notifier).setNickname('도로친구');
    await seed
        .read(demoProfileProvider.notifier)
        .completeOnboarding(MovementType.walking);
    seed.dispose();

    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('로그인 화면')),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => Consumer(
            builder: (context, ref, child) {
              final profile = ref.watch(demoProfileProvider);
              return Scaffold(
                body: Text('${profile.nickname} ${profile.movementType.label}'),
              );
            },
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          anonymousIdentityProvider.overrideWith((ref) async => 'anonymous'),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('도로친구 보행 기여'), findsOneWidget);
    expect(find.text('로그인 화면'), findsNothing);
  });
}
