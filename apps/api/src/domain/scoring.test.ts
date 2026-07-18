import { describe, expect, it } from "vitest";
import { calculateRoadScore, roadGrade } from "./scoring.js";

describe("Road DNA score", () => {
  it("returns unknown when no events exist", () => {
    expect(calculateRoadScore(null)).toEqual({
      confidence: 0,
      confidenceLevel: "LOW",
      grade: "UNKNOWN",
      score: null,
    });
  });

  it("never mixes missing data with a perfect score", () => {
    expect(roadGrade(null)).toBe("UNKNOWN");
    expect(roadGrade(100)).toBe("GOOD");
  });

  it("grows confidence as contributors repeat a signal", () => {
    const low = calculateRoadScore({
      averageRms: 2,
      averageSeverity: 0.7,
      eventCount: 1,
      lastDetectedAt: new Date().toISOString(),
      traversalCount: 1,
      uniqueContributorCount: 1,
    });
    const high = calculateRoadScore({
      averageRms: 2,
      averageSeverity: 0.7,
      eventCount: 20,
      lastDetectedAt: new Date().toISOString(),
      traversalCount: 20,
      uniqueContributorCount: 20,
    });

    expect(low.confidenceLevel).toBe("LOW");
    expect(high.confidenceLevel).toBe("HIGH");
    expect(high.confidence).toBeGreaterThan(low.confidence);
  });
});
