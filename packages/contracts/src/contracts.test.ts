import { Value } from "@sinclair/typebox/value";
import { describe, expect, it } from "vitest";
import {
  CreateSensorEventRequestSchema,
  MovementTypeSchema,
  RoadMapItemSchema,
} from "./index.js";

describe("API contracts", () => {
  it("keeps walking data as an explicit movement type", () => {
    expect(Value.Check(MovementTypeSchema, "WALKING")).toBe(true);
    expect(Value.Check(MovementTypeSchema, "ALL")).toBe(false);
  });

  it("rejects impossible coordinates and severity", () => {
    expect(
      Value.Check(CreateSensorEventRequestSchema, {
        anomalyScore: 0.82,
        detectedAt: "2026-07-18T13:10:00Z",
        gpsAccuracy: 4.2,
        impactLevel: "HIGH_IMPACT",
        latitude: 120,
        longitude: 126.8526,
        movementType: "WHEELCHAIR",
        peakValue: 3.42,
        severity: 1.2,
      }),
    ).toBe(false);
  });

  it("allows unknown road scores only as null", () => {
    expect(
      Value.Check(RoadMapItemSchema, {
        confidence: 0,
        confidenceLevel: "LOW",
        eventCount: 0,
        grade: "UNKNOWN",
        latitude: 35.1595,
        longitude: 126.8526,
        movementType: "STROLLER",
        roadName: "분석 전 도로",
        roadSegmentId: "d189be1f-e2d5-4b90-8cec-360ec343be99",
        score: null,
        updatedAt: "2026-07-18T13:10:00Z",
      }),
    ).toBe(true);
  });
});
