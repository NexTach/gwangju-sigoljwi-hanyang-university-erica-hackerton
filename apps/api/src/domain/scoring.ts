import type {
  ConfidenceLevel,
  ImpactLevel,
  RoadGrade,
} from "@road-dna/contracts";

export interface RoadAggregate {
  averageRms: number;
  averageSeverity: number;
  eventCount: number;
  lastDetectedAt: string;
  traversalCount: number;
  uniqueContributorCount: number;
}

export interface RoadScoreResult {
  confidence: number;
  confidenceLevel: ConfidenceLevel;
  grade: RoadGrade;
  score: number | null;
}

const clamp = (value: number, minimum: number, maximum: number): number =>
  Math.min(maximum, Math.max(minimum, value));

export function roadGrade(score: number | null): RoadGrade {
  if (score === null) return "UNKNOWN";
  if (score >= 80) return "GOOD";
  if (score >= 60) return "NORMAL";
  if (score >= 40) return "CAUTION";
  return "POOR";
}

export function confidenceLevel(value: number): ConfidenceLevel {
  if (value >= 0.8) return "HIGH";
  if (value >= 0.5) return "MEDIUM";
  return "LOW";
}

export function impactLevel(severity: number): ImpactLevel {
  if (severity >= 0.75) return "HIGH_IMPACT";
  if (severity >= 0.5) return "MEDIUM_IMPACT";
  return "LOW_IMPACT";
}

export function calculateRoadScore(
  aggregate: RoadAggregate | null,
  now = new Date(),
): RoadScoreResult {
  if (!aggregate || aggregate.eventCount === 0) {
    return {
      confidence: 0,
      confidenceLevel: "LOW",
      grade: "UNKNOWN",
      score: null,
    };
  }

  const denominator = Math.max(
    aggregate.traversalCount,
    aggregate.uniqueContributorCount,
    1,
  );
  const frequency = aggregate.eventCount / denominator;
  const impactPenalty = frequency * aggregate.averageSeverity * 38;
  const vibrationPenalty = clamp(aggregate.averageRms / 10, 0, 1) * 12;
  const score = Math.round(
    clamp(100 - Math.min(80, impactPenalty + vibrationPenalty), 0, 100),
  );

  const volumeWeight = clamp(aggregate.eventCount / 20, 0, 1) * 0.35;
  const userWeight = clamp(aggregate.uniqueContributorCount / 20, 0, 1) * 0.3;
  const repeatabilityWeight =
    clamp(
      aggregate.eventCount / Math.max(aggregate.uniqueContributorCount, 1) / 4,
      0,
      1,
    ) * 0.2;
  const ageDays =
    Math.max(0, now.getTime() - new Date(aggregate.lastDetectedAt).getTime()) /
    86_400_000;
  const recencyWeight =
    ageDays <= 7 ? 0.15 : ageDays <= 30 ? 0.1 : ageDays <= 90 ? 0.05 : 0;
  const confidence = Number(
    clamp(
      volumeWeight + userWeight + repeatabilityWeight + recencyWeight,
      0,
      1,
    ).toFixed(4),
  );

  return {
    confidence,
    confidenceLevel: confidenceLevel(confidence),
    grade: roadGrade(score),
    score,
  };
}
