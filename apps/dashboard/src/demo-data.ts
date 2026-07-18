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

export const yongbongDemoBounds = {
  maximumLatitude: 35.1873028,
  maximumLongitude: 126.9157899,
  minimumLatitude: 35.1716449,
  minimumLongitude: 126.8862124,
} as const;

export const yongbongDemoCenter = {
  latitude: 35.1788215,
  longitude: 126.900505,
} as const;

const roadProfiles = [
  {
    confidence: 0.46,
    confidenceLevel: "LOW",
    eventCount: 8,
    latitude: 35.1757018,
    longitude: 126.9059674,
    roadName: "민주대로",
    roadSegmentId: "10000000-0000-4000-8000-000000000101",
    scores: [86, 85, 84],
  },
  {
    confidence: 0.65,
    confidenceLevel: "MEDIUM",
    eventCount: 16,
    latitude: 35.1785726,
    longitude: 126.9032665,
    roadName: "반룡로",
    roadSegmentId: "10000000-0000-4000-8000-000000000132",
    scores: [39, 36, 34],
  },
  {
    confidence: 0.555,
    confidenceLevel: "MEDIUM",
    eventCount: 12,
    latitude: 35.177446,
    longitude: 126.9010286,
    roadName: "설죽로202번길",
    roadSegmentId: "10000000-0000-4000-8000-000000000204",
    scores: [59, 57, 55],
  },
  {
    confidence: 0.46,
    confidenceLevel: "LOW",
    eventCount: 8,
    latitude: 35.1826485,
    longitude: 126.9016026,
    roadName: "고운로",
    roadSegmentId: "10000000-0000-4000-8000-000000000245",
    scores: [83, 82, 80],
  },
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
    roadProfiles.map((profile, index) => {
      const score = profile.scores[movementIndex] ?? profile.scores[0];
      return {
        confidence: profile.confidence,
        confidenceLevel: profile.confidenceLevel,
        eventCount: profile.eventCount,
        grade: grade(score),
        latitude: profile.latitude,
        longitude: profile.longitude,
        movementType,
        roadName: profile.roadName,
        roadSegmentId: profile.roadSegmentId,
        score,
        updatedAt: new Date(Date.now() - index * 180_000).toISOString(),
      };
    }),
);

const knownDemoRoads = demoRoads.filter(
  (road): road is RoadMapItem & { score: number } => road.score !== null,
);

export const demoOverview: DashboardOverviewResponse = {
  accessibilityIndex: Number(
    (
      knownDemoRoads.reduce((sum, road) => sum + road.score, 0) /
      knownDemoRoads.length
    ).toFixed(1),
  ),
  acceptedEventCount: demoRoads.reduce((sum, road) => sum + road.eventCount, 0),
  activeContributors: 24,
  analyzedDistanceMeters: knownDemoRoads.length * 10,
  highConfidenceRoadCount: knownDemoRoads.filter(
    (road) => road.confidenceLevel === "HIGH",
  ).length,
  roadCount: knownDemoRoads.length,
  unknownRoadCount: demoRoads.length - knownDemoRoads.length,
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
  const roadScores = demoRoads.filter(
    (item) => item.roadSegmentId === roadSegmentId,
  );
  return {
    eventCount: roadScores.reduce((sum, item) => sum + item.eventCount, 0),
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
      const item = roadScores.find(
        (candidate) => candidate.movementType === movementType,
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
