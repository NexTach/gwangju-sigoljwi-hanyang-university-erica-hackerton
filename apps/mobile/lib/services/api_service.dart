import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/app_config.dart';
import '../core/models.dart';

class RoadDnaApiException implements Exception {
  const RoadDnaApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RoadDnaApi {
  RoadDnaApi(AppConfig config, {Dio? dio})
    : _demoMode = config.demoMode,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: config.apiBaseUrl,
              connectTimeout: const Duration(seconds: 5),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              receiveTimeout: const Duration(seconds: 8),
              sendTimeout: const Duration(seconds: 8),
            ),
          );

  final Dio _dio;
  final bool _demoMode;
  static const _uuid = Uuid();

  Future<MovementSession> startSession({
    required String anonymousUserId,
    required MovementType movementType,
  }) async {
    if (_demoMode) {
      return MovementSession(
        movementType: movementType,
        sessionId: _uuid.v4(),
        startedAt: DateTime.now().toUtc(),
      );
    }
    return _request(
      () async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/api/v1/sessions',
          data: {
            'anonymousUserId': anonymousUserId,
            'appVersion': '0.1.0',
            'deviceModel': 'Flutter device',
            'movementType': movementType.apiName,
            'startedAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
        return MovementSession.fromJson(response.data!);
      },
    );
  }

  Future<void> endSession(String sessionId) async {
    if (_demoMode) return;
    await _request(
      () => _dio.patch<void>(
        '/api/v1/sessions/$sessionId/end',
        data: {'endedAt': DateTime.now().toUtc().toIso8601String()},
      ),
    );
  }

  Future<EventReceipt> sendCandidate({
    required ImpactCandidate candidate,
    required LocationReading location,
    required MovementType movementType,
    required String sessionId,
  }) async {
    if (_demoMode) {
      return EventReceipt(
        eventId: _uuid.v4(),
        roadSegmentId: candidate.isPossibleDrop ? null : _uuid.v4(),
        status: candidate.isPossibleDrop
            ? 'HELD_DROP_PATTERN'
            : location.accuracy > 25
            ? 'HELD_LOW_GPS_ACCURACY'
            : location.speed < 0.25
            ? 'REJECTED_STATIONARY'
            : 'ACCEPTED',
      );
    }
    return _request(
      () async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/api/v1/sessions/$sessionId/events',
          data: {
            'anomalyScore': candidate.anomalyScore,
            'detectedAt': candidate.detectedAt.toUtc().toIso8601String(),
            'gpsAccuracy': location.accuracy,
            'impactLevel': candidate.impactLevel.apiName,
            'latitude': location.latitude,
            'longitude': location.longitude,
            'movementType': movementType.apiName,
            'peakValue': candidate.features.maxPeak,
            'severity': candidate.severity,
            'speed': location.speed,
            'window': candidate.features.toJson(),
          },
        );
        return EventReceipt.fromJson(response.data!);
      },
    );
  }

  Future<List<RoadMapItem>> nearbyRoads({
    required double latitude,
    required double longitude,
    required MovementType movementType,
    int radius = 1000,
  }) async {
    if (_demoMode) {
      return _demoRoads(movementType);
    }
    return _request(
      () async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/api/v1/roads/nearby',
          queryParameters: {
            'latitude': latitude,
            'longitude': longitude,
            'movementType': movementType.apiName,
            'radius': radius,
          },
        );
        return (response.data!['roads'] as List<dynamic>)
            .map(
              (road) => RoadMapItem.fromJson(road as Map<String, dynamic>),
            )
            .toList(growable: false);
      },
    );
  }

  Future<RoadDetail> roadDetail(String roadSegmentId) async {
    if (_demoMode) {
      final road = _demoRoads(MovementType.wheelchair).firstWhere(
        (road) => road.roadSegmentId == roadSegmentId,
        orElse: () => _demoRoads(MovementType.wheelchair).first,
      );
      return RoadDetail(
        eventCount: 36,
        roadName: road.roadName,
        roadSegmentId: roadSegmentId,
        scores: MovementType.values
            .map(
              (movement) => MovementRoadScore(
                confidence: 0.72,
                eventCount: 12,
                grade: road.grade,
                movementType: movement,
                score: (road.score! - movement.index * 4)
                    .clamp(0, 100)
                    .toInt(),
              ),
            )
            .toList(growable: false),
        updatedAt: road.updatedAt,
      );
    }
    return _request(
      () async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/api/v1/roads/$roadSegmentId',
        );
        return RoadDetail.fromJson(response.data!);
      },
    );
  }

  Future<RouteComparison> compareRoutes({
    required double destinationLatitude,
    required double destinationLongitude,
    required MovementType movementType,
    required double originLatitude,
    required double originLongitude,
  }) async {
    if (_demoMode) {
      return RouteComparison(
        disclaimer: '명시적 데모 모드의 거리 기반 시연 경로예요.',
        routes: [
          RouteOption(
            accessibilityScore: 43,
            coordinates: [
              (latitude: originLatitude, longitude: originLongitude),
              (
                latitude: destinationLatitude,
                longitude: destinationLongitude,
              ),
            ],
            distance: 520,
            duration: 480,
            source: 'MVP_ESTIMATE',
            type: RouteType.fastest,
          ),
          RouteOption(
            accessibilityScore: 91,
            coordinates: [
              (latitude: originLatitude, longitude: originLongitude),
              (
                latitude:
                    (originLatitude + destinationLatitude) / 2 + 0.0003,
                longitude:
                    (originLongitude + destinationLongitude) / 2 - 0.0002,
              ),
              (
                latitude: destinationLatitude,
                longitude: destinationLongitude,
              ),
            ],
            distance: 640,
            duration: 660,
            source: 'ROAD_DNA',
            type: RouteType.accessible,
          ),
        ],
      );
    }
    return _request(
      () async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/api/v1/routes',
          queryParameters: {
            'destinationLat': destinationLatitude,
            'destinationLng': destinationLongitude,
            'movementType': movementType.apiName,
            'originLat': originLatitude,
            'originLng': originLongitude,
          },
        );
        return RouteComparison.fromJson(response.data!);
      },
    );
  }

  Future<T> _request<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        throw RoadDnaApiException(data['message'] as String);
      }
      final message = switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => '서버 응답이 늦어요. 네트워크를 확인해 주세요.',
        DioExceptionType.connectionError => 'Road DNA 서버에 연결할 수 없어요.',
        _ => '요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.',
      };
      throw RoadDnaApiException(message);
    }
  }

  List<RoadMapItem> _demoRoads(MovementType movementType) {
    const values = [
      (35.15958, 126.85261, 88),
      (35.15976, 126.85288, 72),
      (35.15993, 126.85315, 54),
      (35.16010, 126.85342, 32),
    ];
    return [
      for (final (index, value) in values.indexed)
        RoadMapItem(
          confidence: 0.42 + index * 0.14,
          eventCount: 6 + index * 8,
          grade: value.$3 >= 80
              ? RoadGrade.good
              : value.$3 >= 60
              ? RoadGrade.normal
              : value.$3 >= 40
              ? RoadGrade.caution
              : RoadGrade.poor,
          latitude: value.$1,
          longitude: value.$2,
          movementType: movementType,
          roadName: '상무중앙로 ${index + 1}구간',
          roadSegmentId: '20000000-0000-4000-8000-00000000000$index',
          score: value.$3,
          updatedAt: DateTime.now().toUtc().subtract(
            Duration(minutes: index * 4),
          ),
        ),
    ];
  }
}
