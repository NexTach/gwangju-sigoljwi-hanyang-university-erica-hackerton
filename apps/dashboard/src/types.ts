import type { MovementType } from "@road-dna/contracts";

export type MovementFilter = MovementType | "ALL";

export const movementLabel: Record<MovementFilter, string> = {
  ALL: "전체",
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

export const gradeTone = {
  CAUTION: "warning",
  GOOD: "success",
  NORMAL: "info",
  POOR: "critical",
  UNKNOWN: "neutral",
} as const;
