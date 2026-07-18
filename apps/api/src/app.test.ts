import { randomUUID } from "node:crypto";
import { afterEach, describe, expect, it } from "vitest";
import { buildApp } from "./app.js";
import { MemoryEventDeduplicator } from "./data/deduplicator.js";
import { MemoryRoadRepository } from "./data/memory-repository.js";

const apps: ReturnType<typeof buildApp>[] = [];

const makeApp = () => {
  const app = buildApp({
    deduplicator: new MemoryEventDeduplicator(),
    repository: new MemoryRoadRepository(),
  });
  apps.push(app);
  return app;
};

afterEach(async () => {
  await Promise.all(apps.splice(0).map((app) => app.close()));
});

describe("Road DNA API", () => {
  it("reports repository and deduplicator readiness", async () => {
    const response = await makeApp().inject({ method: "GET", url: "/health" });

    expect(response.statusCode).toBe(200);
    expect(response.json()).toMatchObject({
      checks: { database: true, redis: true },
      service: "road-dna-api",
      status: "ok",
    });
  });

  it("generates reverse-proxy-safe API documentation URLs", async () => {
    const app = buildApp({
      deduplicator: new MemoryEventDeduplicator(),
      publicPathPrefix: "/road-dna",
      repository: new MemoryRoadRepository(),
    });
    apps.push(app);

    const html = await app.inject({ method: "GET", url: "/docs/" });
    expect(html.statusCode).toBe(200);
    expect(html.body).toContain('href="./static/swagger-ui.css"');

    const initializer = await app.inject({
      method: "GET",
      url: "/docs/static/swagger-initializer.js",
    });
    expect(initializer.statusCode).toBe(200);
    expect(initializer.body).toContain("url: resolveUrl('./json')");

    const specification = await app.inject({
      method: "GET",
      url: "/docs/json",
    });
    expect(specification.statusCode).toBe(200);
    expect(specification.json()).toMatchObject({
      servers: [{ url: "/road-dna/api/v1" }],
    });
  });

  it("accepts Flutter timestamps with microseconds", async () => {
    const response = await makeApp().inject({
      method: "POST",
      payload: {
        anonymousUserId: randomUUID(),
        movementType: "WHEELCHAIR",
        startedAt: "2026-07-18T08:50:39.123456Z",
      },
      url: "/api/v1/sessions",
    });

    expect(response.statusCode).toBe(201);
  });

  it("runs the session, event, road and dashboard lifecycle", async () => {
    const app = makeApp();
    const startedAt = new Date(Date.now() - 60_000).toISOString();
    const sessionResponse = await app.inject({
      method: "POST",
      payload: {
        anonymousUserId: randomUUID(),
        movementType: "WHEELCHAIR",
        startedAt,
      },
      url: "/api/v1/sessions",
    });
    expect(sessionResponse.statusCode).toBe(201);
    const session = sessionResponse.json<{ sessionId: string }>();

    const event = {
      anomalyScore: 0.8,
      detectedAt: new Date().toISOString(),
      gpsAccuracy: 5,
      impactLevel: "HIGH_IMPACT",
      latitude: 35.15958,
      longitude: 126.85261,
      movementType: "WHEELCHAIR",
      peakValue: 5.2,
      severity: 0.84,
      speed: 1.1,
      window: {
        durationMs: 2_000,
        maxPeak: 5.2,
        mean: 0.8,
        peakCount: 3,
        rms: 2.4,
        standardDeviation: 1.1,
      },
    };
    const eventResponse = await app.inject({
      method: "POST",
      payload: event,
      url: `/api/v1/sessions/${session.sessionId}/events`,
    });
    expect(eventResponse.statusCode).toBe(201);
    expect(eventResponse.json()).toMatchObject({
      status: "ACCEPTED",
    });

    const nearbyResponse = await app.inject({
      method: "GET",
      url:
        "/api/v1/roads/nearby?latitude=35.15958&longitude=126.85261" +
        "&movementType=WHEELCHAIR&radius=100",
    });
    expect(nearbyResponse.statusCode).toBe(200);
    const nearby = nearbyResponse.json<{
      roads: Array<{ roadSegmentId: string; score: number }>;
    }>();
    expect(nearby.roads).toHaveLength(1);
    expect(nearby.roads[0]?.score).toBeLessThan(100);

    const detailResponse = await app.inject({
      method: "GET",
      url: `/api/v1/roads/${nearby.roads[0]!.roadSegmentId}`,
    });
    expect(detailResponse.statusCode).toBe(200);
    expect(detailResponse.json()).toMatchObject({
      eventCount: 1,
      scores: expect.arrayContaining([
        expect.objectContaining({ movementType: "WHEELCHAIR" }),
        expect.objectContaining({ movementType: "STROLLER", score: null }),
      ]),
    });

    const dashboardResponse = await app.inject({
      method: "GET",
      url: "/api/v1/dashboard/overview?movementType=WHEELCHAIR",
    });
    expect(dashboardResponse.statusCode).toBe(200);
    expect(dashboardResponse.json()).toMatchObject({
      acceptedEventCount: 1,
      activeContributors: 1,
      roadCount: 1,
    });

    const endResponse = await app.inject({
      method: "PATCH",
      payload: { endedAt: new Date().toISOString() },
      url: `/api/v1/sessions/${session.sessionId}/end`,
    });
    expect(endResponse.statusCode).toBe(200);
    expect(endResponse.json()).toMatchObject({ status: "COMPLETED" });
  });

  it("holds unsafe candidates and rejects movement mismatches", async () => {
    const app = makeApp();
    const sessionResponse = await app.inject({
      method: "POST",
      payload: {
        anonymousUserId: randomUUID(),
        movementType: "STROLLER",
        startedAt: new Date(Date.now() - 60_000).toISOString(),
      },
      url: "/api/v1/sessions",
    });
    const { sessionId } = sessionResponse.json<{ sessionId: string }>();
    const candidate = {
      anomalyScore: 0.9,
      detectedAt: new Date().toISOString(),
      gpsAccuracy: 40,
      impactLevel: "HIGH_IMPACT",
      latitude: 35.15958,
      longitude: 126.85261,
      movementType: "STROLLER",
      peakValue: 6,
      severity: 0.9,
    };
    const held = await app.inject({
      method: "POST",
      payload: candidate,
      url: `/api/v1/sessions/${sessionId}/events`,
    });
    expect(held.statusCode).toBe(201);
    expect(held.json()).toMatchObject({
      roadSegmentId: null,
      status: "HELD_LOW_GPS_ACCURACY",
    });

    const mismatch = await app.inject({
      method: "POST",
      payload: { ...candidate, movementType: "WALKING" },
      url: `/api/v1/sessions/${sessionId}/events`,
    });
    expect(mismatch.statusCode).toBe(422);
    expect(mismatch.json()).toMatchObject({
      code: "MOVEMENT_TYPE_MISMATCH",
    });
  });
});
