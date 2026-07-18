import type {
  DashboardOverviewResponse,
  MovementType,
  NearbyRoadsResponse,
  PriorityRoadsResponse,
  RoadDetailResponse,
  RoadGrade,
  RoadMapItem,
} from "@road-dna/contracts";

const movements: MovementType[] = ["WHEELCHAIR", "STROLLER", "WALKING"];
const centers = [
  [35.15958, 126.85261, 88],
  [35.15976, 126.85288, 73],
  [35.15993, 126.85315, 59],
  [35.1601, 126.85342, 42],
  [35.16028, 126.85369, 27],
] as const;

const grade = (score: number): RoadGrade =>
  score >= 80
    ? "GOOD"
    : score >= 60
      ? "NORMAL"
      : score >= 40
        ? "CAUTION"
        : "POOR";

export const demoRoads: RoadMapItem[] = movements.flatMap(
  (movementType, movementIndex) =>
    centers.map(([latitude, longitude, baseScore], index) => {
      const score = Math.max(12, baseScore - movementIndex * 4);
      return {
        confidence: Number((0.48 + index * 0.1).toFixed(2)),
        confidenceLevel: index >= 4 ? "HIGH" : index >= 1 ? "MEDIUM" : "LOW",
        eventCount: 8 + index * 7,
        grade: grade(score),
        latitude,
        longitude,
        movementType,
        roadName: `상무중앙로 ${index + 1}구간`,
        roadSegmentId: `1000000${movementIndex}-0000-4000-8000-00000000000${index}`,
        score,
        updatedAt: new Date(Date.now() - index * 180_000).toISOString(),
      };
    }),
);

export const demoOverview: DashboardOverviewResponse = {
  accessibilityIndex: 61.8,
  acceptedEventCount: 120,
  activeContributors: 24,
  analyzedDistanceMeters: 150,
  highConfidenceRoadCount: 3,
  roadCount: 15,
  unknownRoadCount: 0,
};

export function demoNearby(movementType?: MovementType): NearbyRoadsResponse {
  return {
    roads: demoRoads.filter(
      (road) => !movementType || road.movementType === movementType,
    ),
  };
}

export function demoPriorities(
  movementType?: MovementType,
): PriorityRoadsResponse {
  return {
    roads: demoNearby(movementType)
      .roads.sort(
        (first, second) => (first.score ?? 100) - (second.score ?? 100),
      )
      .slice(0, 8)
      .map(
        ({
          confidence,
          confidenceLevel,
          eventCount,
          grade: roadGrade,
          movementType: type,
          roadName,
          roadSegmentId,
          score,
        }) => ({
          confidence,
          confidenceLevel,
          eventCount,
          grade: roadGrade,
          movementType: type,
          roadName,
          roadSegmentId,
          score: score ?? 0,
        }),
      ),
  };
}

export function demoDetail(roadSegmentId: string): RoadDetailResponse {
  const road = demoRoads.find((item) => item.roadSegmentId === roadSegmentId);
  if (!road) throw new Error("도로 구간을 찾을 수 없어요.");
  return {
    eventCount: road.eventCount,
    lastDetectedAt: road.updatedAt,
    latitude: road.latitude,
    longitude: road.longitude,
    recentEvents: [
      {
        detectedAt: road.updatedAt,
        gpsAccuracy: 4.8,
        impactLevel: road.score! < 45 ? "HIGH_IMPACT" : "MEDIUM_IMPACT",
        severity: Number(((100 - road.score!) / 100).toFixed(2)),
      },
    ],
    roadName: road.roadName,
    roadSegmentId,
    scores: movements.map((movementType) => {
      const item = demoRoads.find(
        (candidate) =>
          candidate.movementType === movementType &&
          candidate.latitude === road.latitude,
      )!;
      return {
        confidence: item.confidence,
        confidenceLevel: item.confidenceLevel,
        eventCount: item.eventCount,
        grade: item.grade,
        movementType,
        score: item.score,
      };
    }),
    updatedAt: road.updatedAt,
  };
}
