import { randomUUID } from "node:crypto";
import type {
  CreateSensorEventRequest,
  MovementType,
} from "@road-dna/contracts";
import type { RoadRepository } from "../data/repository.js";

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

export const demoRoadProfiles = [
  {
    latitude: 35.1757018,
    longitude: 126.9059674,
    repeatCounts: [1, 1, 1, 1, 1, 1, 1, 1],
    roadName: "민주대로",
    severity: 0.3,
  },
  {
    latitude: 35.1785726,
    longitude: 126.9032665,
    repeatCounts: [2, 2, 2, 2, 2, 2, 2, 2],
    roadName: "반룡로",
    severity: 0.75,
  },
  {
    latitude: 35.177446,
    longitude: 126.9010286,
    repeatCounts: [2, 1, 2, 1, 2, 1, 2, 1],
    roadName: "설죽로202번길",
    severity: 0.65,
  },
  {
    latitude: 35.1826485,
    longitude: 126.9016026,
    repeatCounts: [1, 1, 1, 1, 1, 1, 1, 1],
    roadName: "고운로",
    severity: 0.38,
  },
] as const;

export async function seedDemoData(
  repository: RoadRepository,
): Promise<{ eventCount: number; sessionCount: number }> {
  const now = Date.now();
  let eventCount = 0;
  let sessionCount = 0;

  for (const [movementIndex, movementType] of movements.entries()) {
    for (let contributor = 0; contributor < 8; contributor += 1) {
      const startedAt = new Date(
        now - (contributor + movementIndex + 1) * 60_000,
      ).toISOString();
      const session = await repository.createSession({
        anonymousUserId: randomUUID(),
        appVersion: "demo-seed",
        deviceModel: "Road DNA simulator",
        movementType,
        startedAt,
      });
      sessionCount += 1;

      for (const [roadIndex, road] of demoRoadProfiles.entries()) {
        const severity = Math.min(0.94, road.severity + movementIndex * 0.035);
        const jitter = contributor * 0.000001;
        const repeatCount = road.repeatCounts[contributor] ?? 1;

        for (let repeat = 0; repeat < repeatCount; repeat += 1) {
          const event: CreateSensorEventRequest = {
            anomalyScore: Number(Math.min(0.99, severity + 0.08).toFixed(3)),
            detectedAt: new Date(
              now -
                ((contributor * demoRoadProfiles.length + roadIndex) * 2 +
                  repeat +
                  1) *
                  4_000,
            ).toISOString(),
            gpsAccuracy: 4 + (contributor % 4),
            impactLevel:
              severity >= 0.75
                ? "HIGH_IMPACT"
                : severity >= 0.5
                  ? "MEDIUM_IMPACT"
                  : "LOW_IMPACT",
            latitude: road.latitude + jitter + repeat * 0.0000002,
            longitude: road.longitude + jitter + repeat * 0.0000002,
            movementType,
            peakValue: Number((2.2 + severity * 4).toFixed(3)),
            severity: Number(severity.toFixed(3)),
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
          eventCount += 1;
        }
      }
      await repository.endSession(
        session.sessionId,
        new Date(now).toISOString(),
      );
    }
  }

  return { eventCount, sessionCount };
}
