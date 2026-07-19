import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/screens/login_screen.dart';
import 'package:road_dna_mobile/ui/companion_theme.dart';

void main() {
  group('Describe 초기 화면 소개 캐러셀', () {
    group('Context 사용자가 조작하지 않고 화면을 보고 있는 경우', () {
      testWidgets('It 시간에 따라 좌우 애니메이션으로 순환한다', (tester) async {
        await _pumpLoginScreen(tester);

        final controller = _pageController(tester);
        expect(controller.page, 3000);
        expect(_activeDot(0), findsOneWidget);
        expect(_visibleSlideCount(tester), 1);

        await tester.pump(const Duration(milliseconds: 3500));
        await tester.pump(const Duration(milliseconds: 160));

        expect(controller.page, greaterThan(3000));
        expect(controller.page, lessThan(3001));

        await tester.pumpAndSettle();
        expect(controller.page, 3001);
        expect(_activeDot(1), findsOneWidget);
        expect(_visibleSlideCount(tester), 1);

        await _waitForAutomaticAdvance(tester);
        expect(controller.page, 3002);
        expect(_activeDot(2), findsOneWidget);

        await _waitForAutomaticAdvance(tester);
        expect(controller.page, 3003);
        expect(_activeDot(0), findsOneWidget);
        expect(_visibleSlideCount(tester), 1);
      });
    });

    group('Context 사용자가 소개 화면을 직접 넘긴 경우', () {
      testWidgets('It 손가락을 따라 이동한 뒤 자동 순환을 다시 시작한다', (tester) async {
        await _pumpLoginScreen(tester);

        final controller = _pageController(tester);
        final carousel = find.byKey(const ValueKey('login-carousel-page-view'));
        final gesture = await tester.startGesture(tester.getCenter(carousel));
        await gesture.moveBy(const Offset(-180, 0));
        await tester.pump(const Duration(milliseconds: 80));

        expect(controller.page, greaterThan(3000));
        expect(controller.page, lessThan(3001));

        await gesture.moveBy(const Offset(-100, 0));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(controller.page, 3001);
        expect(_activeDot(1), findsOneWidget);
        expect(_visibleSlideCount(tester), 1);

        await _waitForAutomaticAdvance(tester);

        expect(controller.page, 3002);
        expect(_activeDot(2), findsOneWidget);
        expect(_visibleSlideCount(tester), 1);
      });
    });

    group('Context 캐러셀 화면이 사라진 경우', () {
      testWidgets('It 예약된 자동 전환을 안전하게 정리한다', (tester) async {
        await _pumpLoginScreen(tester);

        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        await tester.pump(const Duration(seconds: 4));

        expect(tester.takeException(), isNull);
      });
    });
  });
}

Future<void> _pumpLoginScreen(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(430, 932);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: companionTheme(),
      home: const LoginScreen(
        initialLifecycleStateOverride: AppLifecycleState.resumed,
      ),
    ),
  );
  await tester.pump();
}

PageController _pageController(WidgetTester tester) => tester
    .widget<PageView>(find.byKey(const ValueKey('login-carousel-page-view')))
    .controller!;

Finder _activeDot(int index) =>
    find.byKey(ValueKey('login-carousel-dot-$index-active'));

Future<void> _waitForAutomaticAdvance(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 3500));
  await tester.pumpAndSettle();
}

int _visibleSlideCount(WidgetTester tester) {
  final viewport = tester.getRect(
    find.byKey(const ValueKey('login-carousel-viewport')),
  );
  var visibleCount = 0;
  for (var index = 0; index < 3; index += 1) {
    final slides = find.byKey(
      ValueKey('login-carousel-slide-$index'),
      skipOffstage: false,
    );
    for (var match = 0; match < slides.evaluate().length; match += 1) {
      final overlap = viewport.intersect(tester.getRect(slides.at(match)));
      if (overlap.width > 0.5 && overlap.height > 0.5) {
        visibleCount += 1;
      }
    }
  }
  return visibleCount;
}
