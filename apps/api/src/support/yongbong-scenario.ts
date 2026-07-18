import { randomUUID } from "node:crypto";
import type {
  CreateSensorEventRequest,
  MovementType,
} from "@road-dna/contracts";
import { distanceMeters } from "../domain/geo.js";
import { impactLevel } from "../domain/scoring.js";
import type { RoadRepository } from "../data/repository.js";

export interface ScenarioCoordinate {
  latitude: number;
  longitude: number;
}

export interface YongbongRoadProfile extends ScenarioCoordinate {
  geometry: readonly ScenarioCoordinate[];
  repeatCounts: readonly number[];
  roadName: string;
  roadSegmentId: string;
  scores: readonly [number, number, number];
}

const movements: readonly MovementType[] = [
  "WHEELCHAIR",
  "STROLLER",
  "WALKING",
];

export const yongbongBounds = {
  maximumLatitude: 35.1873028,
  maximumLongitude: 126.9157899,
  minimumLatitude: 35.1716449,
  minimumLongitude: 126.8862124,
} as const;

export const yongbongCenter = {
  latitude: 35.1788215,
  longitude: 126.900505,
} as const;

export const yongbongRoadProfiles: readonly YongbongRoadProfile[] = [
  {
    geometry: [
      { latitude: 35.176063, longitude: 126.90438 },
      { latitude: 35.175568, longitude: 126.905835 },
      { latitude: 35.175547, longitude: 126.905929 },
      { latitude: 35.175699, longitude: 126.905981 },
    ],
    latitude: 35.1757018,
    longitude: 126.9059674,
    repeatCounts: [1, 1, 1, 1, 1, 1, 1, 1],
    roadName: "민주대로",
    roadSegmentId: "10000000-0000-4000-8000-000000000101",
    scores: [86, 85, 84],
  },
  {
    geometry: [
      { latitude: 35.178262, longitude: 126.902367 },
      { latitude: 35.178758, longitude: 126.902511 },
      { latitude: 35.178682, longitude: 126.902884 },
      { latitude: 35.178641, longitude: 126.903091 },
      { latitude: 35.178603, longitude: 126.903276 },
    ],
    latitude: 35.1785726,
    longitude: 126.9032665,
    repeatCounts: [2, 2, 2, 2, 2, 2, 2, 2],
    roadName: "반룡로",
    roadSegmentId: "10000000-0000-4000-8000-000000000132",
    scores: [39, 36, 34],
  },
  {
    geometry: [
      { latitude: 35.177342, longitude: 126.89936 },
      { latitude: 35.177105, longitude: 126.900579 },
      { latitude: 35.177107, longitude: 126.900715 },
      { latitude: 35.17718, longitude: 126.901104 },
    ],
    latitude: 35.17718,
    longitude: 126.901104,
    repeatCounts: [2, 1, 2, 1, 2, 1, 2, 1],
    roadName: "설죽로202번길",
    roadSegmentId: "10000000-0000-4000-8000-000000000204",
    scores: [59, 57, 55],
  },
  {
    geometry: [
      { latitude: 35.180824, longitude: 126.900445 },
      { latitude: 35.18127, longitude: 126.901541 },
      { latitude: 35.181749, longitude: 126.901313 },
      { latitude: 35.182124, longitude: 126.901131 },
      { latitude: 35.182473, longitude: 126.900953 },
      { latitude: 35.182689, longitude: 126.901582 },
    ],
    latitude: 35.1826485,
    longitude: 126.9016026,
    repeatCounts: [1, 1, 1, 1, 1, 1, 1, 1],
    roadName: "고운로",
    roadSegmentId: "10000000-0000-4000-8000-000000000245",
    scores: [83, 82, 80],
  },
  {
    geometry: [
      { latitude: 35.178459, longitude: 126.897206 },
      { latitude: 35.178466, longitude: 126.897073 },
      { latitude: 35.178756, longitude: 126.897089 },
      { latitude: 35.179123, longitude: 126.89711 },
      { latitude: 35.179141, longitude: 126.896634 },
      { latitude: 35.179505, longitude: 126.896651 },
    ],
    latitude: 35.179505,
    longitude: 126.896651,
    repeatCounts: [3, 3, 3, 3, 3, 2, 2, 2],
    roadName: "설죽로217번길",
    roadSegmentId: "10000000-0000-4000-8000-000000000217",
    scores: [92, 90, 91],
  },
  {
    geometry: [
      { latitude: 35.179789, longitude: 126.900076 },
      { latitude: 35.179681, longitude: 126.900641 },
      { latitude: 35.179558, longitude: 126.901275 },
      { latitude: 35.179494, longitude: 126.90165 },
      { latitude: 35.179434, longitude: 126.901966 },
      { latitude: 35.179426, longitude: 126.902012 },
      { latitude: 35.179374, longitude: 126.902292 },
    ],
    latitude: 35.179374,
    longitude: 126.902292,
    repeatCounts: [2, 2, 2, 2, 2, 2, 1, 1],
    roadName: "반룡로41번길",
    roadSegmentId: "10000000-0000-4000-8000-000000000241",
    scores: [76, 73, 75],
  },
  {
    geometry: [
      { latitude: 35.180261, longitude: 126.900206 },
      { latitude: 35.180029, longitude: 126.901398 },
      { latitude: 35.180497, longitude: 126.901536 },
    ],
    latitude: 35.180497,
    longitude: 126.901536,
    repeatCounts: [3, 3, 2, 2, 2, 2, 2, 2],
    roadName: "반룡로27번길",
    roadSegmentId: "10000000-0000-4000-8000-000000000227",
    scores: [48, 45, 51],
  },
  {
    geometry: [
      { latitude: 35.180824, longitude: 126.900445 },
      { latitude: 35.18127, longitude: 126.901541 },
      { latitude: 35.181749, longitude: 126.901313 },
      { latitude: 35.182124, longitude: 126.901131 },
      { latitude: 35.182473, longitude: 126.900953 },
    ],
    latitude: 35.182473,
    longitude: 126.900953,
    repeatCounts: [3, 2, 2, 2, 2, 2, 2, 2],
    roadName: "용주로30번길",
    roadSegmentId: "10000000-0000-4000-8000-000000000230",
    scores: [84, 81, 83],
  },
] as const;

const profileById = new Map(
  yongbongRoadProfiles.map((profile) => [profile.roadSegmentId, profile]),
);

const maximumRoadHintDistanceMeters = 80;

export function isWithinYongbongBounds(location: ScenarioCoordinate): boolean {
  return (
    location.latitude >= yongbongBounds.minimumLatitude &&
    location.latitude <= yongbongBounds.maximumLatitude &&
    location.longitude >= yongbongBounds.minimumLongitude &&
    location.longitude <= yongbongBounds.maximumLongitude
  );
}

function distanceToSegmentMeters(
  point: ScenarioCoordinate,
  start: ScenarioCoordinate,
  end: ScenarioCoordinate,
): number {
  const latitudeScale = 111_320;
  const longitudeScale =
    latitudeScale * Math.max(Math.cos((point.latitude * Math.PI) / 180), 0.2);
  const startX = (start.longitude - point.longitude) * longitudeScale;
  const startY = (start.latitude - point.latitude) * latitudeScale;
  const endX = (end.longitude - point.longitude) * longitudeScale;
  const endY = (end.latitude - point.latitude) * latitudeScale;
  const deltaX = endX - startX;
  const deltaY = endY - startY;
  const lengthSquared = deltaX * deltaX + deltaY * deltaY;
  const fraction =
    lengthSquared === 0
      ? 0
      : Math.min(
          1,
          Math.max(0, -(startX * deltaX + startY * deltaY) / lengthSquared),
        );
  return Math.hypot(startX + deltaX * fraction, startY + deltaY * fraction);
}

export function distanceToRoadMeters(
  location: ScenarioCoordinate,
  road: YongbongRoadProfile,
): number {
  let nearest = distanceMeters(location, road);
  for (let index = 0; index < road.geometry.length - 1; index += 1) {
    const start = road.geometry[index];
    const end = road.geometry[index + 1];
    if (start && end) {
      nearest = Math.min(
        nearest,
        distanceToSegmentMeters(location, start, end),
      );
    }
  }
  return nearest;
}

export function matchYongbongRoadHint(
  event: Pick<
    CreateSensorEventRequest,
    "latitude" | "longitude" | "roadSegmentIdHint"
  >,
): YongbongRoadProfile | null {
  if (!event.roadSegmentIdHint) return null;
  const road = profileById.get(event.roadSegmentIdHint);
  if (!road) return null;
  return distanceToRoadMeters(event, road) <= maximumRoadHintDistanceMeters
    ? road
    : null;
}

const eventCount = (road: YongbongRoadProfile): number =>
  road.repeatCounts.reduce((sum, count) => sum + count, 0);

const severityForScore = (
  road: YongbongRoadProfile,
  movementIndex: number,
): number => {
  const targetScore = road.scores[movementIndex] ?? road.scores[0];
  const traversals = road.repeatCounts.filter((count) => count > 0).length;
  const frequency = eventCount(road) / Math.max(traversals, 1);
  const severity = (100 - targetScore - 0.96) / (frequency * 38 + 3.84);
  return Number(Math.min(0.94, Math.max(0.01, severity)).toFixed(3));
};

export async function seedYongbongScenario(
  repository: RoadRepository,
): Promise<{ eventCount: number; sessionCount: number }> {
  await repository.upsertRoadSegments(yongbongRoadProfiles);

  const missingByMovement = new Map<MovementType, Set<string>>(
    movements.map((movementType) => [movementType, new Set<string>()]),
  );
  for (const road of yongbongRoadProfiles) {
    const detail = await repository.getRoadDetail(road.roadSegmentId);
    for (const movementType of movements) {
      const score = detail?.scores.find(
        (candidate) => candidate.movementType === movementType,
      );
      if (!score || score.eventCount === 0) {
        missingByMovement.get(movementType)?.add(road.roadSegmentId);
      }
    }
  }

  const now = Date.now();
  let seededEventCount = 0;
  let sessionCount = 0;

  for (const [movementIndex, movementType] of movements.entries()) {
    const missingRoadIds = missingByMovement.get(movementType);
    if (!missingRoadIds || missingRoadIds.size === 0) continue;

    for (let contributor = 0; contributor < 8; contributor += 1) {
      const roadsForContributor = yongbongRoadProfiles.filter(
        (road) =>
          missingRoadIds.has(road.roadSegmentId) &&
          (road.repeatCounts[contributor] ?? 0) > 0,
      );
      if (roadsForContributor.length === 0) continue;

      const startedAt = new Date(
        now - (contributor + movementIndex + 1) * 60_000,
      ).toISOString();
      const session = await repository.createSession({
        anonymousUserId: randomUUID(),
        appVersion: "scenario-seed-v1",
        deviceModel: "Road DNA scenario",
        movementType,
        startedAt,
      });
      sessionCount += 1;

      for (const [roadIndex, road] of roadsForContributor.entries()) {
        const severity = severityForScore(road, movementIndex);
        const repeatCount = road.repeatCounts[contributor] ?? 0;
        for (let repeat = 0; repeat < repeatCount; repeat += 1) {
          const event: CreateSensorEventRequest = {
            anomalyScore: Number(Math.min(0.99, severity + 0.08).toFixed(3)),
            detectedAt: new Date(
              now -
                ((contributor * yongbongRoadProfiles.length + roadIndex) * 3 +
                  repeat +
                  1) *
                  4_000,
            ).toISOString(),
            gpsAccuracy: 4 + (contributor % 4),
            impactLevel: impactLevel(severity),
            latitude: road.latitude + contributor * 0.000001,
            longitude: road.longitude + contributor * 0.000001,
            movementType,
            peakValue: Number((2.2 + severity * 4).toFixed(3)),
            roadSegmentIdHint: road.roadSegmentId,
            severity,
            speed: 1.05,
            window: {
              durationMs: 2_000,
              maxPeak: Number((2.2 + severity * 4).toFixed(3)),
              mean: Number((0.3 + severity).toFixed(3)),
              peakCount: roadIndex + repeat + 1,
              rms: Number((0.8 + severity * 3.2).toFixed(3)),
              standardDeviation: Number((0.2 + severity * 0.9).toFixed(3)),
            },
          };
          await repository.recordEvent(session, event, "ACCEPTED");
          seededEventCount += 1;
        }
      }
      await repository.endSession(
        session.sessionId,
        new Date(now).toISOString(),
      );
    }
  }

  return { eventCount: seededEventCount, sessionCount };
}
