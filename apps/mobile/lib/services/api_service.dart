import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/app_config.dart';
import '../core/geo.dart';
import '../core/models.dart';
import '../demo/yongbong_demo_data.dart';

typedef AnonymousContributionPermission = bool Function();

String formatApiTimestamp(DateTime value) =>
    DateTime.fromMillisecondsSinceEpoch(
      value.toUtc().millisecondsSinceEpoch,
      isUtc: true,
    ).toIso8601String();

class RoadDnaApiException implements Exception {
  const RoadDnaApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RoadDnaApi {
  RoadDnaApi(
    AppConfig config, {
    AnonymousContributionPermission? allowAnonymousContributions,
    Dio? dio,
  }) : _allowAnonymousContributions =
           allowAnonymousContributions ?? _allowContributions,
       _demoMode = config.demoMode,
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

  static const _privateSessionPrefix = 'local-private-';
  final Dio _dio;
  final AnonymousContributionPermission _allowAnonymousContributions;
  final bool _demoMode;
  static const _uuid = Uuid();

  static bool _allowContributions() => true;

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
    if (!_allowAnonymousContributions()) {
      return MovementSession(
        movementType: movementType,
        sessionId: '$_privateSessionPrefix${_uuid.v4()}',
        startedAt: DateTime.now().toUtc(),
      );
    }
    return _request(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sessions',
        data: {
          'anonymousUserId': anonymousUserId,
          'appVersion': '0.1.3',
          'deviceModel': 'Flutter device',
          'movementType': movementType.apiName,
          'startedAt': formatApiTimestamp(DateTime.now()),
        },
      );
      return MovementSession.fromJson(response.data!);
    });
  }

  Future<void> endSession(String sessionId) async {
    if (_demoMode ||
        sessionId.startsWith(_privateSessionPrefix) ||
        !_allowAnonymousContributions()) {
      return;
    }
    await _request(
      () => _dio.patch<void>(
        '/api/v1/sessions/$sessionId/end',
        data: {'endedAt': formatApiTimestamp(DateTime.now())},
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
      return _localReceipt(
        candidate: candidate,
        location: location,
        roadSegmentId: candidate.isPossibleDrop
            ? null
            : _nearestDemoRoad(location, movementType).roadSegmentId,
      );
    }
    if (sessionId.startsWith(_privateSessionPrefix) ||
        !_allowAnonymousContributions()) {
      return _localReceipt(candidate: candidate, location: location);
    }
    return _request(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/sessions/$sessionId/events',
        data: {
          'anomalyScore': candidate.anomalyScore,
          'detectedAt': formatApiTimestamp(candidate.detectedAt),
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
    });
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
    return _request(() async {
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
          .map((road) => RoadMapItem.fromJson(road as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<RoadDetail> roadDetail(String roadSegmentId) async {
    if (_demoMode) {
      final road = _demoRoads(MovementType.wheelchair).firstWhere(
        (road) => road.roadSegmentId == roadSegmentId,
        orElse: () => _demoRoads(MovementType.wheelchair).first,
      );
      return RoadDetail(
        eventCount: road.eventCount * MovementType.values.length,
        roadName: road.roadName,
        roadSegmentId: roadSegmentId,
        scores: MovementType.values
            .map((movement) {
              final movementRoad = _demoRoads(movement).firstWhere(
                (candidate) => candidate.roadSegmentId == road.roadSegmentId,
              );
              return MovementRoadScore(
                confidence: movementRoad.confidence,
                eventCount: movementRoad.eventCount,
                grade: movementRoad.grade,
                movementType: movement,
                score: movementRoad.score,
              );
            })
            .toList(growable: false),
        updatedAt: road.updatedAt,
      );
    }
    return _request(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/roads/$roadSegmentId',
      );
      return RoadDetail.fromJson(response.data!);
    });
  }

  Future<RouteComparison> compareRoutes({
    required double destinationLatitude,
    required double destinationLongitude,
    required MovementType movementType,
    required double originLatitude,
    required double originLongitude,
  }) async {
    if (_demoMode) {
      return YongbongDemoData.routeComparison;
    }
    return _request(() async {
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
    });
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

  List<RoadMapItem> _demoRoads(MovementType movementType) =>
      YongbongDemoData.roads(movementType);

  EventReceipt _localReceipt({
    required ImpactCandidate candidate,
    required LocationReading location,
    String? roadSegmentId,
  }) => EventReceipt(
    eventId: _uuid.v4(),
    roadSegmentId: candidate.isPossibleDrop ? null : roadSegmentId,
    status: candidate.isPossibleDrop
        ? 'HELD_DROP_PATTERN'
        : location.accuracy > 25
        ? 'HELD_LOW_GPS_ACCURACY'
        : location.speed < 0.25
        ? 'REJECTED_STATIONARY'
        : 'ACCEPTED',
  );

  RoadMapItem _nearestDemoRoad(
    LocationReading location,
    MovementType movementType,
  ) => _demoRoads(movementType).reduce((nearest, candidate) {
    double distanceTo(RoadMapItem road) => distanceMeters(
      firstLatitude: location.latitude,
      firstLongitude: location.longitude,
      secondLatitude: road.latitude,
      secondLongitude: road.longitude,
    );
    return distanceTo(candidate) < distanceTo(nearest) ? candidate : nearest;
  });
}
