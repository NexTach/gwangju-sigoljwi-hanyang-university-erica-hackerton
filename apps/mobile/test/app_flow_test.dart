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

      await _pumpUntil(tester, find.text('Road DNA 측정 시작'));
      expect(find.text('명시적 데모 센서'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Road DNA 측정 시작'));
      await _pumpUntil(tester, find.text('어떻게 이동하고 있나요?'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('휴대폰 고정 확인'), findsOneWidget);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -560),
      );
      await tester.pump();
      await tester.tap(find.text('이 유형으로 측정 시작'));
      await _pumpUntil(tester, find.text('도로 분석 중'));
      expect(find.text('측정 종료'), findsOneWidget);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(RoadDnaApp)),
      );
      await container.read(trackingProvider.notifier).injectDebugImpact();
      await _pumpUntil(tester, find.text('이동 충격 패턴을 감지했어요'));
      expect(container.read(trackingProvider).acceptedEvents, 1);
      expect(container.read(trackingProvider).status, TrackingStatus.active);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('측정 종료'));
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
      await _pumpUntil(tester, find.text('이동이 도시 데이터가 됐어요'));
      expect(
        find.text('원본 센서 신호는 전송하지 않았고, 수용된 충격 후보와 도로 구간만 집계했어요.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('permanently denied location access explains the settings path', (
    tester,
  ) async {
    _usePhoneViewport(tester);
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

    await _pumpUntil(tester, find.text('권한 허용하고 시작'));
    await tester.tap(find.text('권한 허용하고 시작'));
    await _pumpUntil(tester, find.text('기기 설정 열기'));
    expect(find.text('설정에서 권한을 허용해 주세요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
