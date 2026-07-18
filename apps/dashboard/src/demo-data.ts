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

export const yongbongMapBounds = {
  maximumLatitude: 35.183,
  maximumLongitude: 126.90625,
  minimumLatitude: 35.1753,
  minimumLongitude: 126.89635,
} as const;

export type RoadGeometry = Array<[longitude: number, latitude: number]>;

export const roadGeometryById: Record<string, RoadGeometry> = {
  "10000000-0000-4000-8000-000000000101": [
    [126.90438, 35.176063],
    [126.905835, 35.175568],
    [126.905929, 35.175547],
    [126.905981, 35.175699],
  ],
  "10000000-0000-4000-8000-000000000132": [
    [126.902367, 35.178262],
    [126.902511, 35.178758],
    [126.902884, 35.178682],
    [126.903091, 35.178641],
    [126.903276, 35.178603],
  ],
  "10000000-0000-4000-8000-000000000204": [
    [126.89936, 35.177342],
    [126.900579, 35.177105],
    [126.900715, 35.177107],
    [126.901104, 35.17718],
  ],
  "10000000-0000-4000-8000-000000000245": [
    [126.900445, 35.180824],
    [126.901541, 35.18127],
    [126.901313, 35.181749],
    [126.901131, 35.182124],
    [126.900953, 35.182473],
    [126.901582, 35.182689],
  ],
  "10000000-0000-4000-8000-000000000217": [
    [126.897206, 35.178459],
    [126.897073, 35.178466],
    [126.897089, 35.178756],
    [126.89711, 35.179123],
    [126.896634, 35.179141],
    [126.896651, 35.179505],
  ],
  "10000000-0000-4000-8000-000000000241": [
    [126.900076, 35.179789],
    [126.900641, 35.179681],
    [126.901275, 35.179558],
    [126.90165, 35.179494],
    [126.901966, 35.179434],
    [126.902012, 35.179426],
    [126.902292, 35.179374],
  ],
  "10000000-0000-4000-8000-000000000227": [
    [126.900206, 35.180261],
    [126.901398, 35.180029],
    [126.901536, 35.180497],
  ],
  "10000000-0000-4000-8000-000000000230": [
    [126.900445, 35.180824],
    [126.901541, 35.18127],
    [126.901313, 35.181749],
    [126.901131, 35.182124],
    [126.900953, 35.182473],
  ],
};

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
    latitude: 35.17718,
    longitude: 126.901104,
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
  {
    confidence: 0.7512,
    confidenceLevel: "MEDIUM",
    eventCount: 21,
    latitude: 35.179505,
    longitude: 126.896651,
    roadName: "설죽로217번길",
    roadSegmentId: "10000000-0000-4000-8000-000000000217",
    scores: [92, 90, 91],
  },
  {
    confidence: 0.6025,
    confidenceLevel: "MEDIUM",
    eventCount: 14,
    latitude: 35.179374,
    longitude: 126.902292,
    roadName: "반룡로41번길",
    roadSegmentId: "10000000-0000-4000-8000-000000000241",
    scores: [76, 73, 75],
  },
  {
    confidence: 0.6975,
    confidenceLevel: "MEDIUM",
    eventCount: 18,
    latitude: 35.180497,
    longitude: 126.901536,
    roadName: "반룡로27번길",
    roadSegmentId: "10000000-0000-4000-8000-000000000227",
    scores: [48, 45, 51],
  },
  {
    confidence: 0.6737,
    confidenceLevel: "MEDIUM",
    eventCount: 17,
    latitude: 35.182473,
    longitude: 126.900953,
    roadName: "용주로30번길",
    roadSegmentId: "10000000-0000-4000-8000-000000000230",
    scores: [84, 81, 83],
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
const knownDemoRoadIds = new Set(
  knownDemoRoads.map((road) => road.roadSegmentId),
);
const highConfidenceDemoRoadIds = new Set(
  knownDemoRoads
    .filter((road) => road.confidenceLevel === "HIGH")
    .map((road) => road.roadSegmentId),
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
  analyzedDistanceMeters: knownDemoRoadIds.size * 10,
  highConfidenceRoadCount: highConfidenceDemoRoadIds.size,
  roadCount: knownDemoRoadIds.size,
  unknownRoadCount: roadProfiles.length - knownDemoRoadIds.size,
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
  const worstByRoad = new Map<string, RoadMapItem>();
  for (const road of demoNearby(movementType).roads) {
    const current = worstByRoad.get(road.roadSegmentId);
    if (!current || (road.score ?? 100) < (current.score ?? 100)) {
      worstByRoad.set(road.roadSegmentId, road);
    }
  }
  return {
    roads: [...worstByRoad.values()]
      .sort((first, second) => {
        const firstPriority =
          (100 - (first.score ?? 100)) * (0.5 + first.confidence);
        const secondPriority =
          (100 - (second.score ?? 100)) * (0.5 + second.confidence);
        return (
          secondPriority - firstPriority ||
          (first.score ?? 100) - (second.score ?? 100)
        );
      })
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
