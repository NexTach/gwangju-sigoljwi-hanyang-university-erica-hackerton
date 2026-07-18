import type { CreateSensorEventRequest } from "@road-dna/contracts";
import { afterEach, describe, expect, it, vi } from "vitest";
import { MemoryEventDeduplicator } from "./deduplicator.js";

const event = (
  overrides: Partial<CreateSensorEventRequest> = {},
): CreateSensorEventRequest => ({
  anomalyScore: 0.8,
  detectedAt: "2026-07-19T00:00:01.000Z",
  gpsAccuracy: 5,
  impactLevel: "HIGH_IMPACT",
  latitude: 35.1786,
  longitude: 126.9007,
  movementType: "WHEELCHAIR",
  peakValue: 6,
  severity: 0.8,
  ...overrides,
});

afterEach(() => {
  vi.useRealTimers();
});

describe("Describe MemoryEventDeduplicator.isDuplicate", () => {
  describe("Context 같은 세션·좌표·5초 감지 구간이 반복된 경우", () => {
    it("It 유효 시간 안의 두 번째 이벤트만 중복으로 판정한다", async () => {
      vi.useFakeTimers();
      vi.setSystemTime("2026-07-19T00:00:00.000Z");
      const deduplicator = new MemoryEventDeduplicator();

      await expect(
        deduplicator.isDuplicate("session-a", event()),
      ).resolves.toBe(false);
      await expect(
        deduplicator.isDuplicate("session-a", event()),
      ).resolves.toBe(true);

      vi.advanceTimersByTime(5_000);
      await expect(
        deduplicator.isDuplicate("session-a", event()),
      ).resolves.toBe(false);
    });
  });

  describe("Context 세션이나 감지 구간이 다른 경우", () => {
    it("It 서로 독립된 이벤트로 판정한다", async () => {
      const deduplicator = new MemoryEventDeduplicator();

      await deduplicator.isDuplicate("session-a", event());

      await expect(
        deduplicator.isDuplicate("session-b", event()),
      ).resolves.toBe(false);
      await expect(
        deduplicator.isDuplicate(
          "session-a",
          event({ detectedAt: "2026-07-19T00:00:06.000Z" }),
        ),
      ).resolves.toBe(false);
    });
  });
});
