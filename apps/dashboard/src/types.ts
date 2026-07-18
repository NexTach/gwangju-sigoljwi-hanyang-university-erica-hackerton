import type { MovementType } from "@road-dna/contracts";

export const movementLabel: Record<MovementType, string> = {
  STROLLER: "유모차",
  WALKING: "일반 보행",
  WHEELCHAIR: "휠체어",
};

export const gradeLabel = {
  CAUTION: "주의",
  GOOD: "양호",
  NORMAL: "보통",
  POOR: "불편",
  UNKNOWN: "데이터 없음",
} as const;
