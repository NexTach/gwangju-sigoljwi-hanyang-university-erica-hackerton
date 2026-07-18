import type { CreateSensorEventRequest } from "@road-dna/contracts";
import { describe, expect, it } from "vitest";
import { classifyEvent } from "./event-policy.js";

const candidate = (
  overrides: Partial<CreateSensorEventRequest> = {},
): CreateSensorEventRequest => ({
  anomalyScore: 0.8,
  detectedAt: "2026-07-19T00:00:00.000Z",
  gpsAccuracy: 5,
  impactLevel: "HIGH_IMPACT",
  latitude: 35.1786,
  longitude: 126.9007,
  movementType: "WHEELCHAIR",
  peakValue: 6,
  severity: 0.8,
  speed: 1,
  window: {
    durationMs: 2_000,
    maxPeak: 6,
    mean: 1.2,
    peakCount: 3,
    rms: 2,
    standardDeviation: 0.8,
  },
  ...overrides,
});

describe("Describe classifyEvent", () => {
  describe("Context 측정 품질이나 움직임이 안전 기준을 벗어난 경우", () => {
    it("It 가장 먼저 적용되는 보류·거절 사유를 반환한다", () => {
      expect(classifyEvent(candidate({ gpsAccuracy: 25.1, speed: 0 }))).toBe(
        "HELD_LOW_GPS_ACCURACY",
      );
      expect(classifyEvent(candidate({ speed: 0.24 }))).toBe(
        "REJECTED_STATIONARY",
      );
      expect(
        classifyEvent(
          candidate({
            peakValue: 25.1,
            window: { ...candidate().window!, peakCount: 1 },
          }),
        ),
      ).toBe("HELD_DROP_PATTERN");
      expect(classifyEvent(candidate({ severity: 0.29 }))).toBe(
        "REJECTED_BELOW_THRESHOLD",
      );
    });
  });

  describe("Context 모든 안전 기준을 충족한 경우", () => {
    it("It 이벤트를 승인한다", () => {
      expect(classifyEvent(candidate())).toBe("ACCEPTED");
    });
  });
});
