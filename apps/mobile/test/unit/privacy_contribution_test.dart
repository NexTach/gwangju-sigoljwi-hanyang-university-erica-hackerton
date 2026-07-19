import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/core/app_config.dart';
import 'package:road_dna_mobile/core/models.dart';
import 'package:road_dna_mobile/services/api_service.dart';

void main() {
  group('Describe RoadDnaApi 익명 기여 정책', () {
    group('Context 사용자가 익명 데이터 기여를 끈 경우', () {
      test('It 세션과 감지를 로컬에 두고 네트워크를 사용하지 않는다', () async {
        final requestedPaths = <String>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requestedPaths.add(options.path);
                handler.reject(
                  DioException(
                    message: 'Private contribution must stay local.',
                    requestOptions: options,
                  ),
                );
              },
            ),
          );
        final api = RoadDnaApi(
          const AppConfig(
            apiBaseUrl: 'https://example.invalid',
            demoMode: false,
          ),
          allowAnonymousContributions: () => false,
          dio: dio,
        );

        final session = await api.startSession(
          anonymousUserId: 'anonymous',
          movementType: MovementType.walking,
        );
        final receipt = await api.sendCandidate(
          candidate: _candidate(),
          location: _location(),
          movementType: MovementType.walking,
          sessionId: session.sessionId,
        );
        await api.endSession(session.sessionId);

        expect(session.sessionId, startsWith('local-private-'));
        expect(receipt.status, 'ACCEPTED');
        expect(receipt.roadSegmentId, isNull);
        expect(requestedPaths, isEmpty);
      });
    });

    group('Context 로컬 감지 후보의 품질이 안전 기준을 벗어난 경우', () {
      test('It 우선순위에 맞는 보류·거절 상태를 반환한다', () async {
        final api = RoadDnaApi(
          const AppConfig(
            apiBaseUrl: 'https://example.invalid',
            demoMode: false,
          ),
          allowAnonymousContributions: () => false,
        );

        Future<String> status({
          ImpactCandidate? candidate,
          LocationReading? location,
        }) async {
          final receipt = await api.sendCandidate(
            candidate: candidate ?? _candidate(),
            location: location ?? _location(),
            movementType: MovementType.walking,
            sessionId: 'local-private-test',
          );
          return receipt.status;
        }

        await expectLater(
          status(location: _location(accuracy: 25.1, speed: 0)),
          completion('HELD_LOW_GPS_ACCURACY'),
        );
        await expectLater(
          status(location: _location(speed: 0.24)),
          completion('REJECTED_STATIONARY'),
        );
        await expectLater(
          status(candidate: _candidate(isPossibleDrop: true)),
          completion('HELD_DROP_PATTERN'),
        );
        await expectLater(
          status(candidate: _candidate(severity: 0.29)),
          completion('REJECTED_BELOW_THRESHOLD'),
        );
      });
    });
  });
}

ImpactCandidate _candidate({
  bool isPossibleDrop = false,
  double severity = 0.86,
}) => ImpactCandidate(
  anomalyScore: 0.86,
  detectedAt: DateTime.utc(2026, 7, 19, 9),
  features: const SensorWindowFeatures(
    duration: Duration(seconds: 2),
    gyroRms: 1.4,
    maxPeak: 6.2,
    mean: 1.2,
    peakCount: 3,
    rms: 2.1,
    standardDeviation: 1,
  ),
  impactLevel: ImpactLevel.high,
  isPossibleDrop: isPossibleDrop,
  severity: severity,
);

LocationReading _location({double accuracy = 5, double speed = 1.1}) =>
    LocationReading(
      accuracy: accuracy,
      latitude: 35.1786,
      longitude: 126.9007,
      recordedAt: DateTime.utc(2026, 7, 19, 9),
      speed: speed,
    );
