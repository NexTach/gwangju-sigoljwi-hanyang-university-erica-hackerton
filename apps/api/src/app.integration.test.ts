import { randomUUID } from "node:crypto";
import { afterEach, describe, expect, it } from "vitest";
import { buildApp } from "./app.js";
import { MemoryEventDeduplicator } from "./data/deduplicator.js";
import { MemoryRoadRepository } from "./data/memory-repository.js";
import { yongbongRoadProfiles } from "./support/yongbong-scenario.js";

const apps: ReturnType<typeof buildApp>[] = [];

afterEach(async () => {
  await Promise.all(apps.splice(0).map((app) => app.close()));
});

describe("Describe 모바일 이벤트와 Dashboard API 동기화", () => {
  describe("Context 앱이 검증 가능한 용봉동 도로 힌트를 보낸 경우", () => {
    it("It 같은 고정 도로에 기록하고 용봉동 집계에 반영한다", async () => {
      const repository = new MemoryRoadRepository();
      const app = buildApp({
        deduplicator: new MemoryEventDeduplicator(),
        repository,
      });
      apps.push(app);
      await app.ready();
      const road = yongbongRoadProfiles[2]!;
      const location = road.geometry[1]!;

      const sessionResponse = await app.inject({
        method: "POST",
        payload: {
          anonymousUserId: randomUUID(),
          movementType: "WHEELCHAIR",
          startedAt: new Date().toISOString(),
        },
        url: "/api/v1/sessions",
      });
      expect(sessionResponse.statusCode).toBe(201);
      const session = sessionResponse.json<{ sessionId: string }>();

      const eventResponse = await app.inject({
        method: "POST",
        payload: {
          anomalyScore: 0.82,
          detectedAt: new Date().toISOString(),
          gpsAccuracy: 4.2,
          impactLevel: "HIGH_IMPACT",
          latitude: location.latitude,
          longitude: location.longitude,
          movementType: "WHEELCHAIR",
          peakValue: 5.6,
          roadSegmentIdHint: road.roadSegmentId,
          severity: 0.72,
          speed: 1.05,
        },
        url: `/api/v1/sessions/${session.sessionId}/events`,
      });
      expect(eventResponse.statusCode).toBe(201);
      expect(
        eventResponse.json<{ roadSegmentId: string }>().roadSegmentId,
      ).toBe(road.roadSegmentId);

      const detailResponse = await app.inject({
        method: "GET",
        url: `/api/v1/roads/${road.roadSegmentId}`,
      });
      expect(detailResponse.statusCode).toBe(200);
      expect(detailResponse.json<{ roadName: string }>().roadName).toBe(
        "설죽로202번길",
      );

      const overviewResponse = await app.inject({
        method: "GET",
        url: "/api/v1/dashboard/overview",
      });
      expect(overviewResponse.statusCode).toBe(200);
      expect(
        overviewResponse.json<{
          acceptedEventCount: number;
          roadCount: number;
        }>(),
      ).toMatchObject({
        acceptedEventCount: 1,
        roadCount: 1,
      });
    });
  });
});
