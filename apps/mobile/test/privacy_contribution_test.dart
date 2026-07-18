import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:road_dna_mobile/core/app_config.dart';
import 'package:road_dna_mobile/core/models.dart';
import 'package:road_dna_mobile/demo/yongbong_demo_data.dart';
import 'package:road_dna_mobile/services/api_service.dart';

void main() {
  group('Describe RoadDnaApi 익명 기여 정책', () {
    group('Context 내장 용봉동 시나리오에서 익명 기여가 켜진 경우', () {
      test('It 로컬 흐름을 즉시 완료하고 서버 쓰기를 순서대로 미러링한다', () async {
        const remoteSessionId = '20000000-0000-4000-8000-000000000001';
        final releaseRemoteStart = Completer<void>();
        final remoteEndObserved = Completer<void>();
        final requests = <({Object? data, String method, String path})>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) async {
                requests.add((
                  data: options.data,
                  method: options.method,
                  path: options.path,
                ));
                if (options.path == '/api/v1/sessions') {
                  await releaseRemoteStart.future;
                  handler.resolve(
                    Response<Map<String, dynamic>>(
                      data: {
                        'endedAt': null,
                        'movementType': 'WALKING',
                        'sessionId': remoteSessionId,
                        'startedAt': '2026-07-19T09:00:00.000Z',
                        'status': 'ACTIVE',
                      },
                      requestOptions: options,
                      statusCode: 201,
                    ),
                  );
                  return;
                }
                if (options.path.endsWith('/events')) {
                  handler.resolve(
                    Response<Map<String, dynamic>>(
                      data: {
                        'eventId': '30000000-0000-4000-8000-000000000001',
                        'roadSegmentId': YongbongDemoData.seoljuk202RoadId,
                        'status': 'ACCEPTED',
                      },
                      requestOptions: options,
                      statusCode: 201,
                    ),
                  );
                  return;
                }
                if (options.path.endsWith('/end')) {
                  if (!remoteEndObserved.isCompleted) {
                    remoteEndObserved.complete();
                  }
                  handler.resolve(
                    Response<void>(requestOptions: options, statusCode: 200),
                  );
                }
              },
            ),
          );
        final api = RoadDnaApi(
          const AppConfig(
            apiBaseUrl: 'https://example.invalid',
            demoMode: true,
          ),
          allowAnonymousContributions: () => true,
          dio: dio,
        );

        final session = await api.startSession(
          anonymousUserId: 'd189be1f-e2d5-4b90-8cec-360ec343be99',
          movementType: MovementType.walking,
        );
        final receipt = await api.sendCandidate(
          candidate: _candidate,
          location: _location,
          movementType: MovementType.walking,
          sessionId: session.sessionId,
        );
        final endFuture = api.endSession(session.sessionId);
        await Future<void>.delayed(Duration.zero);

        expect(session.sessionId, isNot(remoteSessionId));
        expect(receipt.status, 'ACCEPTED');
        expect(receipt.roadSegmentId, YongbongDemoData.seoljuk202RoadId);
        expect(remoteEndObserved.isCompleted, isFalse);

        releaseRemoteStart.complete();
        await endFuture.timeout(const Duration(seconds: 1));
        expect(remoteEndObserved.isCompleted, isTrue);

        expect(
          requests
              .map((request) => '${request.method} ${request.path}')
              .toList(),
          [
            'POST /api/v1/sessions',
            'POST /api/v1/sessions/$remoteSessionId/events',
            'PATCH /api/v1/sessions/$remoteSessionId/end',
          ],
        );
        final eventPayload = requests[1].data! as Map<String, dynamic>;
        expect(
          eventPayload['roadSegmentIdHint'],
          YongbongDemoData.seoljuk202RoadId,
        );
      });
    });

    group('Context 대기 중인 후보가 있고 사용자가 익명 기여를 끈 경우', () {
      test('It 아직 전송하지 않은 위치 후보는 보내지 않고 원격 세션만 닫는다', () async {
        const remoteSessionId = '20000000-0000-4000-8000-000000000002';
        final releaseRemoteStart = Completer<void>();
        final requests = <String>[];
        var allowsContributions = true;
        final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) async {
                requests.add('${options.method} ${options.path}');
                if (options.path == '/api/v1/sessions') {
                  await releaseRemoteStart.future;
                  handler.resolve(
                    Response<Map<String, dynamic>>(
                      data: {
                        'endedAt': null,
                        'movementType': 'WALKING',
                        'sessionId': remoteSessionId,
                        'startedAt': '2026-07-19T09:00:00.000Z',
                        'status': 'ACTIVE',
                      },
                      requestOptions: options,
                      statusCode: 201,
                    ),
                  );
                  return;
                }
                handler.resolve(
                  Response<void>(requestOptions: options, statusCode: 200),
                );
              },
            ),
          );
        final api = RoadDnaApi(
          const AppConfig(
            apiBaseUrl: 'https://example.invalid',
            demoMode: true,
          ),
          allowAnonymousContributions: () => allowsContributions,
          dio: dio,
        );

        final session = await api.startSession(
          anonymousUserId: 'd189be1f-e2d5-4b90-8cec-360ec343be99',
          movementType: MovementType.walking,
        );
        await api.sendCandidate(
          candidate: _candidate,
          location: _location,
          movementType: MovementType.walking,
          sessionId: session.sessionId,
        );
        allowsContributions = false;
        final endFuture = api.endSession(session.sessionId);

        releaseRemoteStart.complete();
        await endFuture.timeout(const Duration(seconds: 1));

        expect(requests, [
          'POST /api/v1/sessions',
          'PATCH /api/v1/sessions/$remoteSessionId/end',
        ]);
      });
    });

    group('Context 내장 시나리오에서 서버 연결이 실패한 경우', () {
      test('It 로컬 세션과 감지 완료를 유지하고 미러 오류를 격리한다', () async {
        final remoteStartObserved = Completer<void>();
        final requestedPaths = <String>[];
        final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'))
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                requestedPaths.add(options.path);
                if (!remoteStartObserved.isCompleted) {
                  remoteStartObserved.complete();
                }
                handler.reject(
                  DioException(
                    message: 'Road DNA API is offline.',
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                  ),
                );
              },
            ),
          );
        final api = RoadDnaApi(
          const AppConfig(
            apiBaseUrl: 'https://example.invalid',
            demoMode: true,
          ),
          allowAnonymousContributions: () => true,
          dio: dio,
        );

        final session = await api.startSession(
          anonymousUserId: 'd189be1f-e2d5-4b90-8cec-360ec343be99',
          movementType: MovementType.walking,
        );
        final receipt = await api.sendCandidate(
          candidate: _candidate,
          location: _location,
          movementType: MovementType.walking,
          sessionId: session.sessionId,
        );
        await api.endSession(session.sessionId);
        await remoteStartObserved.future.timeout(const Duration(seconds: 1));
        await Future<void>.delayed(Duration.zero);

        expect(receipt.status, 'ACCEPTED');
        expect(receipt.roadSegmentId, YongbongDemoData.seoljuk202RoadId);
        expect(requestedPaths, ['/api/v1/sessions']);
      });
    });

    group('Context 내장 용봉동 시나리오에서 익명 기여가 꺼진 경우', () {
      test('It 모든 세션과 감지를 로컬에 두고 네트워크를 사용하지 않는다', () async {
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
            demoMode: true,
          ),
          allowAnonymousContributions: () => false,
          dio: dio,
        );

        final session = await api.startSession(
          anonymousUserId: 'd189be1f-e2d5-4b90-8cec-360ec343be99',
          movementType: MovementType.walking,
        );
        final receipt = await api.sendCandidate(
          candidate: _candidate,
          location: _location,
          movementType: MovementType.walking,
          sessionId: session.sessionId,
        );
        await api.endSession(session.sessionId);
        await Future<void>.delayed(Duration.zero);

        expect(receipt.status, 'ACCEPTED');
        expect(receipt.roadSegmentId, YongbongDemoData.seoljuk202RoadId);
        expect(requestedPaths, isEmpty);
      });
    });

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
  latitude: YongbongDemoData.originLatitude,
  longitude: YongbongDemoData.originLongitude,
  recordedAt: DateTime.utc(2026, 7, 19, 9),
  speed: 1.1,
);
