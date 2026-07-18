import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:road_dna_design/road_dna_design.dart';

enum MovementType {
  wheelchair('WHEELCHAIR', '휠체어', Icons.accessible_forward_rounded),
  stroller('STROLLER', '유모차', Icons.child_friendly_rounded),
  walking('WALKING', '보행 기여', Icons.directions_walk_rounded);

  const MovementType(this.apiName, this.label, this.icon);

  factory MovementType.fromApi(String value) => values.firstWhere(
    (movement) => movement.apiName == value,
    orElse: () => MovementType.walking,
  );

  final String apiName;
  final IconData icon;
  final String label;
}

enum RoadGrade {
  good('GOOD', '양호'),
  normal('NORMAL', '보통'),
  caution('CAUTION', '주의'),
  poor('POOR', '불편'),
  unknown('UNKNOWN', '데이터 없음');

  const RoadGrade(this.apiName, this.label);

  factory RoadGrade.fromApi(String value) => values.firstWhere(
    (grade) => grade.apiName == value,
    orElse: () => RoadGrade.unknown,
  );

  final String apiName;
  final String label;

  Color color(RdSemanticColors colors) => switch (this) {
    RoadGrade.good => colors.mapGood,
    RoadGrade.normal => colors.mapNormal,
    RoadGrade.caution => colors.mapCaution,
    RoadGrade.poor => colors.mapPoor,
    RoadGrade.unknown => colors.mapUnknown,
  };
}

enum ConfidenceLevel { low, medium, high }

enum ImpactLevel {
  low('LOW_IMPACT', '낮은 충격'),
  medium('MEDIUM_IMPACT', '중간 충격'),
  high('HIGH_IMPACT', '높은 충격');

  const ImpactLevel(this.apiName, this.label);

  final String apiName;
  final String label;
}

@immutable
class LocationReading {
  const LocationReading({
    required this.accuracy,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.speed,
    this.heading,
    this.isMocked = false,
    this.speedAccuracy,
  });

  final double accuracy;
  final double? heading;
  final bool isMocked;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double speed;
  final double? speedAccuracy;
}

@immutable
class MotionSample {
  const MotionSample({
    required this.recordedAt,
    required this.x,
    required this.y,
    required this.z,
    this.gyroX = 0,
    this.gyroY = 0,
    this.gyroZ = 0,
  });

  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final DateTime recordedAt;
  final double x;
  final double y;
  final double z;

  double get magnitude => math.sqrt(x * x + y * y + z * z);
  double get gyroMagnitude =>
      math.sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);
}

@immutable
class SensorWindowFeatures {
  const SensorWindowFeatures({
    required this.duration,
    required this.gyroRms,
    required this.maxPeak,
    required this.mean,
    required this.peakCount,
    required this.rms,
    required this.standardDeviation,
  });

  final Duration duration;
  final double gyroRms;
  final double maxPeak;
  final double mean;
  final int peakCount;
  final double rms;
  final double standardDeviation;

  Map<String, Object> toJson() => {
    'durationMs': duration.inMilliseconds,
    'maxPeak': maxPeak,
    'mean': mean,
    'peakCount': peakCount,
    'rms': rms,
    'standardDeviation': standardDeviation,
  };
}

@immutable
class ImpactCandidate {
  const ImpactCandidate({
    required this.anomalyScore,
    required this.detectedAt,
    required this.features,
    required this.impactLevel,
    required this.isPossibleDrop,
    required this.severity,
  });

  final double anomalyScore;
  final DateTime detectedAt;
  final SensorWindowFeatures features;
  final ImpactLevel impactLevel;
  final bool isPossibleDrop;
  final double severity;
}

@immutable
class MovementSession {
  const MovementSession({
    required this.movementType,
    required this.sessionId,
    required this.startedAt,
  });

  factory MovementSession.fromJson(Map<String, dynamic> json) =>
      MovementSession(
        movementType: MovementType.fromApi(json['movementType'] as String),
        sessionId: json['sessionId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
      );

  final MovementType movementType;
  final String sessionId;
  final DateTime startedAt;
}

@immutable
class EventReceipt {
  const EventReceipt({
    required this.eventId,
    required this.roadSegmentId,
    required this.status,
  });

  factory EventReceipt.fromJson(Map<String, dynamic> json) => EventReceipt(
    eventId: json['eventId'] as String,
    roadSegmentId: json['roadSegmentId'] as String?,
    status: json['status'] as String,
  );

  final String eventId;
  final String? roadSegmentId;
  final String status;
}

@immutable
class RoadMapItem {
  const RoadMapItem({
    required this.confidence,
    required this.eventCount,
    required this.grade,
    required this.latitude,
    required this.longitude,
    required this.movementType,
    required this.roadName,
    required this.roadSegmentId,
    required this.score,
    required this.updatedAt,
  });

  factory RoadMapItem.fromJson(Map<String, dynamic> json) => RoadMapItem(
    confidence: (json['confidence'] as num).toDouble(),
    eventCount: (json['eventCount'] as num).toInt(),
    grade: RoadGrade.fromApi(json['grade'] as String),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    movementType: MovementType.fromApi(json['movementType'] as String),
    roadName: json['roadName'] as String,
    roadSegmentId: json['roadSegmentId'] as String,
    score: (json['score'] as num?)?.toInt(),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final double confidence;
  final int eventCount;
  final RoadGrade grade;
  final double latitude;
  final double longitude;
  final MovementType movementType;
  final String roadName;
  final String roadSegmentId;
  final int? score;
  final DateTime updatedAt;
}

@immutable
class MovementRoadScore {
  const MovementRoadScore({
    required this.confidence,
    required this.eventCount,
    required this.grade,
    required this.movementType,
    required this.score,
  });

  factory MovementRoadScore.fromJson(Map<String, dynamic> json) =>
      MovementRoadScore(
        confidence: (json['confidence'] as num).toDouble(),
        eventCount: (json['eventCount'] as num).toInt(),
        grade: RoadGrade.fromApi(json['grade'] as String),
        movementType: MovementType.fromApi(json['movementType'] as String),
        score: (json['score'] as num?)?.toInt(),
      );

  final double confidence;
  final int eventCount;
  final RoadGrade grade;
  final MovementType movementType;
  final int? score;
}

@immutable
class RoadDetail {
  const RoadDetail({
    required this.eventCount,
    required this.roadName,
    required this.roadSegmentId,
    required this.scores,
    required this.updatedAt,
  });

  factory RoadDetail.fromJson(Map<String, dynamic> json) => RoadDetail(
    eventCount: (json['eventCount'] as num).toInt(),
    roadName: json['roadName'] as String,
    roadSegmentId: json['roadSegmentId'] as String,
    scores: (json['scores'] as List<dynamic>)
        .map(
          (score) => MovementRoadScore.fromJson(score as Map<String, dynamic>),
        )
        .toList(growable: false),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final int eventCount;
  final String roadName;
  final String roadSegmentId;
  final List<MovementRoadScore> scores;
  final DateTime updatedAt;
}

enum RouteType { fastest, accessible }

@immutable
class RouteOption {
  const RouteOption({
    required this.accessibilityScore,
    required this.coordinates,
    required this.distance,
    required this.duration,
    required this.source,
    required this.type,
  });

  factory RouteOption.fromJson(Map<String, dynamic> json) => RouteOption(
    accessibilityScore: (json['accessibilityScore'] as num?)?.toInt(),
    coordinates: (json['geometry'] as List<dynamic>)
        .map((pair) {
          final coordinates = pair as List<dynamic>;
          return (
            latitude: (coordinates[1] as num).toDouble(),
            longitude: (coordinates[0] as num).toDouble(),
          );
        })
        .toList(growable: false),
    distance: (json['distance'] as num).toInt(),
    duration: (json['duration'] as num).toInt(),
    source: json['source'] as String,
    type: json['type'] == 'ACCESSIBLE'
        ? RouteType.accessible
        : RouteType.fastest,
  );

  final int? accessibilityScore;
  final List<({double latitude, double longitude})> coordinates;
  final int distance;
  final int duration;
  final String source;
  final RouteType type;
}

@immutable
class RouteComparison {
  const RouteComparison({required this.disclaimer, required this.routes});

  factory RouteComparison.fromJson(Map<String, dynamic> json) =>
      RouteComparison(
        disclaimer: json['disclaimer'] as String,
        routes: (json['routes'] as List<dynamic>)
            .map((route) => RouteOption.fromJson(route as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String disclaimer;
  final List<RouteOption> routes;
}
