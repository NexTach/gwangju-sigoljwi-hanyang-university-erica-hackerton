import { describe, expect, it } from "vitest";
import {
  calculateRoadScore,
  confidenceLevel,
  impactLevel,
  roadGrade,
  type RoadAggregate,
} from "./scoring.js";

const now = new Date("2026-07-19T00:00:00.000Z");

const aggregate = (overrides: Partial<RoadAggregate> = {}): RoadAggregate => ({
  averageRms: 2,
  averageSeverity: 0.7,
  eventCount: 4,
  lastDetectedAt: "2026-07-18T00:00:00.000Z",
  traversalCount: 4,
  uniqueContributorCount: 4,
  ...overrides,
});

describe("Describe calculateRoadScore", () => {
  describe("Context 이벤트가 없는 도로 구간", () => {
    it("It 점수와 등급을 미확인 상태로 반환한다", () => {
      expect(calculateRoadScore(null, now)).toEqual({
        confidence: 0,
        confidenceLevel: "LOW",
        grade: "UNKNOWN",
        score: null,
      });
    });
  });

  describe("Context 동일한 노면을 더 많은 사용자가 반복 측정한 경우", () => {
    it("It 신뢰도를 높인다", () => {
      const low = calculateRoadScore(aggregate({ eventCount: 1 }), now);
      const high = calculateRoadScore(
        aggregate({
          eventCount: 20,
          traversalCount: 20,
          uniqueContributorCount: 20,
        }),
        now,
      );

      expect(low.confidenceLevel).toBe("LOW");
      expect(high.confidenceLevel).toBe("HIGH");
      expect(high.confidence).toBeGreaterThan(low.confidence);
    });
  });

  describe("Context 충격 빈도와 진동이 커진 경우", () => {
    it("It 접근성 점수를 낮춘다", () => {
      const smooth = calculateRoadScore(
        aggregate({ averageRms: 0.5, averageSeverity: 0.3 }),
        now,
      );
      const rough = calculateRoadScore(
        aggregate({ averageRms: 8, averageSeverity: 0.9, eventCount: 12 }),
        now,
      );

      expect(rough.score).toBeLessThan(smooth.score!);
    });
  });
});

describe("Describe Road DNA 임계값 분류", () => {
  describe("Context 경계값을 분류하는 경우", () => {
    it("It 점수·신뢰도·충격 등급을 지정된 구간에 매핑한다", () => {
      expect([null, 39, 40, 59, 60, 79, 80].map(roadGrade)).toEqual([
        "UNKNOWN",
        "POOR",
        "CAUTION",
        "CAUTION",
        "NORMAL",
        "NORMAL",
        "GOOD",
      ]);

      expect([0.49, 0.5, 0.79, 0.8].map(confidenceLevel)).toEqual([
        "LOW",
        "MEDIUM",
        "MEDIUM",
        "HIGH",
      ]);

      expect([0.49, 0.5, 0.74, 0.75].map(impactLevel)).toEqual([
        "LOW_IMPACT",
        "MEDIUM_IMPACT",
        "MEDIUM_IMPACT",
        "HIGH_IMPACT",
      ]);
    });
  });
});
