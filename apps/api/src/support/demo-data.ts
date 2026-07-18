import { randomUUID } from "node:crypto";
import type {
  CreateSensorEventRequest,
  MovementType,
} from "@road-dna/contracts";
import type { RoadRepository } from "../data/repository.js";

const movements: MovementType[] = ["WHEELCHAIR", "STROLLER", "WALKING"];
const roadCenters = [
  { latitude: 35.15958, longitude: 126.85261 },
  { latitude: 35.15976, longitude: 126.85288 },
  { latitude: 35.15993, longitude: 126.85315 },
  { latitude: 35.1601, longitude: 126.85342 },
  { latitude: 35.16028, longitude: 126.85369 },
];

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

      for (const [roadIndex, center] of roadCenters.entries()) {
        const severity = Math.min(
          0.94,
          0.3 + roadIndex * 0.13 + movementIndex * 0.035,
        );
        const jitter = contributor * 0.000001;
        const event: CreateSensorEventRequest = {
          anomalyScore: Number(Math.min(0.99, severity + 0.08).toFixed(3)),
          detectedAt: new Date(
            now - (contributor * roadCenters.length + roadIndex + 1) * 4_000,
          ).toISOString(),
          gpsAccuracy: 4 + (contributor % 4),
          impactLevel:
            severity >= 0.75
              ? "HIGH_IMPACT"
              : severity >= 0.5
                ? "MEDIUM_IMPACT"
                : "LOW_IMPACT",
          latitude: center.latitude + jitter,
          longitude: center.longitude + jitter,
          movementType,
          peakValue: Number((2.2 + severity * 4).toFixed(3)),
          severity: Number(severity.toFixed(3)),
          speed: 1.05,
          window: {
            durationMs: 2_000,
            maxPeak: Number((2.2 + severity * 4).toFixed(3)),
            mean: Number((0.3 + severity).toFixed(3)),
            peakCount: roadIndex + 1,
            rms: Number((0.8 + severity * 3.2).toFixed(3)),
            standardDeviation: Number((0.2 + severity * 0.9).toFixed(3)),
          },
        };
        await repository.recordEvent(session, event, "ACCEPTED");
        eventCount += 1;
      }
      await repository.endSession(
        session.sessionId,
        new Date(now).toISOString(),
      );
    }
  }

  return { eventCount, sessionCount };
}
