import { Value } from "@sinclair/typebox/value";
import { describe, expect, it } from "vitest";
import {
  CreateSessionRequestSchema,
  CreateSensorEventRequestSchema,
  MovementTypeSchema,
  RoadMapItemSchema,
} from "./index.js";

describe("Describe API 계약 검증", () => {
  describe("Context 이동 유형을 검증하는 경우", () => {
    it("It 실제 측정 유형만 허용한다", () => {
      expect(Value.Check(MovementTypeSchema, "WALKING")).toBe(true);
      expect(Value.Check(MovementTypeSchema, "ALL")).toBe(false);
    });
  });

  describe("Context 센서 이벤트에 불가능한 좌표와 심각도가 들어온 경우", () => {
    it("It 요청을 거절한다", () => {
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
  });

  describe("Context Flutter가 마이크로초 UTC 시각을 보낸 경우", () => {
    it("It 세션 요청을 허용한다", () => {
      expect(
        Value.Check(CreateSessionRequestSchema, {
          anonymousUserId: "d189be1f-e2d5-4b90-8cec-360ec343be99",
          movementType: "WHEELCHAIR",
          startedAt: "2026-07-18T13:10:00.123456Z",
        }),
      ).toBe(true);
    });
  });

  describe("Context 아직 분석되지 않은 도로를 반환하는 경우", () => {
    it("It UNKNOWN 등급과 null 점수 조합을 허용한다", () => {
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
});
