import { type Static, Type } from "@sinclair/typebox";
import {
  ConfidenceLevelSchema,
  MovementTypeSchema,
  RoadGradeSchema,
  UuidSchema,
} from "./common.js";

export const DashboardOverviewQuerySchema = Type.Object({
  movementType: Type.Optional(MovementTypeSchema),
});

export const DashboardOverviewResponseSchema = Type.Object({
  accessibilityIndex: Type.Union([
    Type.Number({ maximum: 100, minimum: 0 }),
    Type.Null(),
  ]),
  acceptedEventCount: Type.Integer({ minimum: 0 }),
  activeContributors: Type.Integer({ minimum: 0 }),
  analyzedDistanceMeters: Type.Integer({ minimum: 0 }),
  highConfidenceRoadCount: Type.Integer({ minimum: 0 }),
  roadCount: Type.Integer({ minimum: 0 }),
  unknownRoadCount: Type.Integer({ minimum: 0 }),
});
export type DashboardOverviewResponse = Static<
  typeof DashboardOverviewResponseSchema
>;

export const PriorityRoadsQuerySchema = Type.Object({
  limit: Type.Integer({ default: 20, maximum: 100, minimum: 1 }),
  movementType: Type.Optional(MovementTypeSchema),
});

export const PriorityRoadSchema = Type.Object({
  confidence: Type.Number({ maximum: 1, minimum: 0 }),
  confidenceLevel: ConfidenceLevelSchema,
  eventCount: Type.Integer({ minimum: 0 }),
  grade: RoadGradeSchema,
  movementType: MovementTypeSchema,
  roadName: Type.String(),
  roadSegmentId: UuidSchema,
  score: Type.Integer({ maximum: 100, minimum: 0 }),
});
export type PriorityRoad = Static<typeof PriorityRoadSchema>;

export const PriorityRoadsResponseSchema = Type.Object({
  roads: Type.Array(PriorityRoadSchema),
});
export type PriorityRoadsResponse = Static<typeof PriorityRoadsResponseSchema>;
