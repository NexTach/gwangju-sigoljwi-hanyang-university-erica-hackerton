import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/core/app_config.dart';
import 'package:road_dna_mobile/core/models.dart';
import 'package:road_dna_mobile/services/api_service.dart';

void main() {
  group('Describe RoadDnaApi 익명 기여 정책', () {
    group('Context 사용자가 익명 데이터 기여를 끈 경우', () {
      test('It 감지는 로컬에 남기고 세션 HTTP 요청을 보내지 않는다', () async {
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
          candidate: _candidate,
          location: _location,
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
  });
}

final _candidate = ImpactCandidate(
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
  isPossibleDrop: false,
  severity: 0.86,
);

final _location = LocationReading(
  accuracy: 5,
  latitude: 35.1786,
  longitude: 126.9007,
  recordedAt: DateTime.utc(2026, 7, 19, 9),
  speed: 1.1,
);
