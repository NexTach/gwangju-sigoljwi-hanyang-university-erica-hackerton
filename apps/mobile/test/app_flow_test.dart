import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/app.dart';
import 'package:road_dna_mobile/core/app_config.dart';
import 'package:road_dna_mobile/core/models.dart';
import 'package:road_dna_mobile/sensing/calibration.dart';
import 'package:road_dna_mobile/services/api_service.dart';
import 'package:road_dna_mobile/services/contribution_store.dart';
import 'package:road_dna_mobile/services/location_service.dart';
import 'package:road_dna_mobile/services/motion_sensor_service.dart';
import 'package:road_dna_mobile/state/providers.dart';
import 'package:road_dna_mobile/state/tracking_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _demoConfig = AppConfig(
  apiBaseUrl: 'https://example.invalid/road-dna',
  demoMode: true,
);

final _location = LocationReading(
  accuracy: 4.2,
  latitude: 35.15958,
  longitude: 126.85261,
  recordedAt: DateTime.utc(2026, 7, 18),
  speed: 1.05,
);

class _GrantedLocationService implements LocationService {
  const _GrantedLocationService();

  @override
  Future<LocationAccess> checkAccess() async => LocationAccess.granted;

  @override
  Future<LocationReading> current() async => _location;

  @override
  Future<LocationAccess> ensureAccess() async => LocationAccess.granted;

  @override
  Future<void> openSettings() async {}

  @override
  Stream<LocationReading> watch() => Stream.value(_location);
}

class _DeniedLocationService implements LocationService {
  const _DeniedLocationService();

  @override
  Future<LocationAccess> checkAccess() async => LocationAccess.denied;

  @override
  Future<LocationReading> current() async => _location;

  @override
  Future<LocationAccess> ensureAccess() async => LocationAccess.deniedForever;

  @override
  Future<void> openSettings() async {}

  @override
  Stream<LocationReading> watch() => const Stream.empty();
}

class _QuietMotionSensorService implements MotionSensorService {
  const _QuietMotionSensorService();

  @override
  Stream<MotionSample> watch() => const Stream.empty();
}

class _MemoryContributionStore extends ContributionStore {
  ContributionSummary _summary = const ContributionSummary.empty();

  @override
  Future<ContributionSummary> addSession({
    required int acceptedEvents,
    required double distanceMeters,
  }) async {
    _summary = ContributionSummary(
      acceptedEvents: _summary.acceptedEvents + acceptedEvents,
      distanceMeters: _summary.distanceMeters + distanceMeters,
      sessions: _summary.sessions + 1,
    );
    return _summary;
  }

  @override
  Future<ContributionSummary> read() async => _summary;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 30,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder.');
}

void _usePhoneViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets(
    'demo flow moves from home through tracking, impact feedback and completion',
    (tester) async {
      _usePhoneViewport(tester);
      SharedPreferences.setMockInitialValues({});
      const locationService = _GrantedLocationService();
      final contributionStore = _MemoryContributionStore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(_demoConfig),
            anonymousIdentityProvider.overrideWith((ref) async => 'anonymous'),
            apiProvider.overrideWithValue(RoadDnaApi(_demoConfig)),
            calibrationProvider.overrideWith(
              (ref) async => const CalibrationSettings.exploratory(),
            ),
            contributionProvider.overrideWith(
              (ref) => contributionStore.read(),
            ),
            contributionStoreProvider.overrideWithValue(contributionStore),
            currentLocationProvider.overrideWith(
              (ref) => locationService.watch(),
            ),
            locationAccessProvider.overrideWith(
              (ref) async => LocationAccess.granted,
            ),
            locationServiceProvider.overrideWithValue(locationService),
            motionSensorServiceProvider.overrideWithValue(
              const _QuietMotionSensorService(),
            ),
          ],
          child: const RoadDnaApp(),
        ),
      );

      await _pumpUntil(tester, find.text('카카오로 3초만에 로그인'));
      await tester.tap(find.text('카카오로 3초만에 로그인'));
      await _pumpUntil(tester, find.text('동의하고 계속하기'));
      await tester.tap(find.text('동의하고 계속하기'));
      await _pumpUntil(tester, find.text('약관에 동의해주세요'));
      await tester.tap(find.text('다음'));
      await _pumpUntil(tester, find.text('뭐라고 불러드릴까요?'));
      await tester.pump(const Duration(milliseconds: 500));
      tester.testTextInput.hide();
      await tester.pump();
      final nicknameNext = find.text('다음');
      await tester.ensureVisible(nicknameNext);
      await tester.tap(nicknameNext);
      await _pumpUntil(tester, find.text('이동 방식을 알려주세요'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('휠체어'), findsOneWidget);
      expect(find.text('유모차'), findsOneWidget);
      expect(find.text('일반 보행'), findsOneWidget);

      await tester.tap(find.text('시작하기'));
      await _pumpUntil(tester, find.text('산책 시작하기'));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('산책 시작하기'));
      await _pumpUntil(tester, find.text('경로를 비교해보세요'));
      await _pumpUntil(tester, find.text('안전한 경로로 출발'));
      expect(find.byType(ChoiceChip), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('안전한 경로로 출발'));
      await _pumpUntil(tester, find.text('함께 걷는 중'));
      expect(find.text('종료'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RoadDnaApp)),
      );
      await container.read(trackingProvider.notifier).injectDebugImpact();
      await _pumpUntil(tester, find.text('이동 충격 패턴을 감지했어요'));
      expect(container.read(trackingProvider).acceptedEvents, 1);
      expect(container.read(trackingProvider).status, TrackingStatus.active);
      expect(tester.takeException(), isNull);

      final barrierWarning = find.text('새로운 이동 충격을 감지했어요');
      await tester.ensureVisible(barrierWarning);
      await tester.tap(barrierWarning);
      await _pumpUntil(tester, find.text('이 구간 피해서 안내받기'));
      await tester.tap(find.text('이 구간 피해서 안내받기'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await _pumpUntil(tester, find.text('오크가 & 3번길 구간을 피한 경로예요'));
      expect(container.read(trackingProvider).status, TrackingStatus.idle);
      expect(
        container
            .read(routerProvider)
            .routeInformationProvider
            .value
            .uri
            .queryParameters['avoidRoad'],
        'demo-132',
      );
      expect(find.text('선택한 위험 구간 제외 · 휠체어 모드'), findsOneWidget);

      await _pumpUntil(tester, find.text('안전한 경로로 출발'));
      await tester.tap(find.text('안전한 경로로 출발'));
      await _pumpUntil(tester, find.text('함께 걷는 중'));
      expect(container.read(trackingProvider).status, TrackingStatus.active);
      await container.read(trackingProvider.notifier).injectDebugImpact();
      expect(container.read(trackingProvider).acceptedEvents, 1);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('종료'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      for (var attempt = 0; attempt < 30; attempt += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (container.read(trackingProvider).status ==
            TrackingStatus.completed) {
          break;
        }
      }
      expect(container.read(trackingProvider).status, TrackingStatus.completed);
      await _pumpUntil(tester, find.text('산책 잘 하셨어요'));
      expect(tester.takeException(), isNull);
      expect(find.text('오늘의 기록'), findsOneWidget);
      expect(find.text('1km의 평탄한 보도를 지났어요'), findsOneWidget);
      expect(find.text('공유하기'), findsOneWidget);
      expect(find.text('경로 저장'), findsOneWidget);

      await tester.tap(find.text('경로 저장'));
      await _pumpUntil(tester, find.text('산책 시작하기'));
      expect(find.text('주변'), findsOneWidget);
      expect(find.text('커뮤니티'), findsOneWidget);
      expect(find.text('리포트'), findsOneWidget);
      expect(find.text('프로필'), findsOneWidget);

      await tester.tap(find.text('커뮤니티'));
      await _pumpUntil(tester, find.text('이웃들이 함께 만드는 용봉동 안전 지도예요'));
      expect(find.text('저도 확인했어요 · 3'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('커뮤니티 글쓰기'));
      await _pumpUntil(tester, find.text('이웃에게 알리기'));
      await tester.enterText(find.byType(TextField), '후문 앞 연석에 경사로가 없어요.');
      await tester.tap(find.text('등록'));
      await _pumpUntil(tester, find.text('후문 앞 연석에 경사로가 없어요.'));
      expect(find.textContaining('방금 전'), findsOneWidget);

      container.read(routerProvider).go('/reports');
      await _pumpUntil(tester, find.text('지금까지의 산책 기록이에요'));
      expect(find.text('용봉로 · 전남대학교 방면'), findsOneWidget);
      expect(find.text('메인가 · 공사 구간 우회'), findsOneWidget);

      container.read(routerProvider).go('/home');
      await _pumpUntil(tester, find.text('산책 시작하기'));
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await _pumpUntil(tester, find.text('산책 리포트가 도착했어요'));
      expect(find.text('오크가 구간 점수가 낮아졌어요'), findsOneWidget);

      container.read(routerProvider).go('/nearby');
      await _pumpUntil(tester, find.text('평탄하고 안전한 구간'));
      await tester.tap(find.text('평탄하고 안전한 구간'));
      await _pumpUntil(tester, find.text('이동하기 편안한 구간'));
      expect(find.text('92'), findsOneWidget);
      expect(tester.takeException(), isNull);

      container.read(routerProvider).go('/profile');
      await _pumpUntil(tester, find.text('MY IMPACT'));
      await tester.tap(find.byIcon(Icons.edit_rounded));
      await _pumpUntil(tester, find.text('저장'));
      await tester.enterText(find.byType(TextField), '도로친구');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _pumpUntil(tester, find.text('도로친구'));
      expect(tester.takeException(), isNull);

      container.read(routerProvider).go('/sensor');
      await _pumpUntil(tester, find.text('Road DNA가 이동을 분석하고 있어요'));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('permanently denied location access explains the settings path', (
    tester,
  ) async {
    _usePhoneViewport(tester);
    SharedPreferences.setMockInitialValues({});
    const locationService = _DeniedLocationService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              apiBaseUrl: 'https://example.invalid/road-dna',
              demoMode: false,
            ),
          ),
          anonymousIdentityProvider.overrideWith((ref) async => 'anonymous'),
          locationAccessProvider.overrideWith(
            (ref) async => LocationAccess.denied,
          ),
          locationServiceProvider.overrideWithValue(locationService),
        ],
        child: const RoadDnaApp(),
      ),
    );

    await _pumpUntil(tester, find.text('카카오로 3초만에 로그인'));
    await tester.tap(find.text('카카오로 3초만에 로그인'));
    await _pumpUntil(tester, find.text('동의하고 계속하기'));
    await tester.tap(find.text('동의하고 계속하기'));
    await _pumpUntil(tester, find.text('기기 설정 열기'));
    expect(find.text('설정에서 권한을 허용해 주세요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
