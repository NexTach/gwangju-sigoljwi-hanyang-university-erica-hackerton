import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:road_dna_mobile/screens/completion_report_screen.dart';
import 'package:road_dna_mobile/screens/walk_reports_screen.dart';
import 'package:road_dna_mobile/ui/companion_theme.dart';
import 'package:road_dna_mobile/ui/demo_report_state.dart';

void _usePhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

GoRouter _reportRouter({required String initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/reports',
      builder: (context, state) => const WalkReportsScreen(),
    ),
    GoRoute(
      path: '/report',
      builder: (context, state) => const CompletionReportScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('데모 홈'))),
    ),
  ],
);

Future<void> _pumpHarness(
  WidgetTester tester, {
  required ProviderContainer container,
  required GoRouter router,
}) => tester.pumpWidget(
  UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router, theme: companionTheme()),
  ),
);

Future<void> _pumpRoute(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('saved report card opens its own date, score and summary', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final container = ProviderContainer();
    final router = _reportRouter(initialLocation: '/reports');
    addTearDown(container.dispose);
    addTearDown(router.dispose);

    await _pumpHarness(tester, container: container, router: router);
    await _pumpRoute(tester);
    await tester.tap(find.text('오크가 · 3번길 구간'));
    await _pumpRoute(tester);

    expect(find.text('어제의 산책 리포트예요'), findsOneWidget);
    expect(find.text('64'), findsOneWidget);
    expect(find.text('일부 구간에서 주의가 필요했어요'), findsOneWidget);
    expect(find.text('오크가 · 3번길 구간'), findsOneWidget);
    expect(find.text('1.4km · 19분 · 휠체어 모드'), findsOneWidget);
    expect(find.text('연석 단차가 있는 구간에서 속도를 낮췄어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving a completed walk adds it to the list and detail route', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    final container = ProviderContainer();
    final router = _reportRouter(initialLocation: '/report');
    addTearDown(container.dispose);
    addTearDown(router.dispose);

    await _pumpHarness(tester, container: container, router: router);
    await _pumpRoute(tester);
    expect(container.read(demoWalkReportsProvider), hasLength(4));

    await tester.tap(find.text('경로 저장'));
    await _pumpRoute(tester);

    final reports = container.read(demoWalkReportsProvider);
    expect(reports, hasLength(5));
    expect(reports.first.place, '용봉로 · 방금 걸은 경로');
    expect(find.text('데모 홈'), findsOneWidget);

    router.go('/reports');
    await _pumpRoute(tester);
    expect(find.text('용봉로 · 방금 걸은 경로'), findsOneWidget);

    await tester.tap(find.text('용봉로 · 방금 걸은 경로'));
    await _pumpRoute(tester);
    expect(find.text('오늘의 산책 리포트예요'), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.text('대체로 편안한 경로였어요'), findsOneWidget);
    expect(find.text('2.2km · 26분 · 휠체어 모드'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
