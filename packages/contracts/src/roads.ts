import { type Static, Type } from "@sinclair/typebox";
import {
  ConfidenceLevelSchema,
  ImpactLevelSchema,
  IsoDateSchema,
  LatitudeSchema,
  LongitudeSchema,
  MovementTypeSchema,
  RoadGradeSchema,
  UuidSchema,
} from "./common.js";

export const NearbyRoadsQuerySchema = Type.Object(
  {
    latitude: LatitudeSchema,
    longitude: LongitudeSchema,
    movementType: MovementTypeSchema,
    radius: Type.Number({ default: 500, maximum: 2000, minimum: 5 }),
  },
  { additionalProperties: false },
);
export type NearbyRoadsQuery = Static<typeof NearbyRoadsQuerySchema>;

export const RoadMapItemSchema = Type.Object({
  confidence: Type.Number({ maximum: 1, minimum: 0 }),
  confidenceLevel: ConfidenceLevelSchema,
  eventCount: Type.Integer({ minimum: 0 }),
  grade: RoadGradeSchema,
  latitude: LatitudeSchema,
  longitude: LongitudeSchema,
  movementType: MovementTypeSchema,
  roadName: Type.String(),
  roadSegmentId: UuidSchema,
  score: Type.Union([Type.Integer({ maximum: 100, minimum: 0 }), Type.Null()]),
  updatedAt: IsoDateSchema,
});
export type RoadMapItem = Static<typeof RoadMapItemSchema>;

export const NearbyRoadsResponseSchema = Type.Object({
  roads: Type.Array(RoadMapItemSchema),
});
export type NearbyRoadsResponse = Static<typeof NearbyRoadsResponseSchema>;

export const RoadDetailParamsSchema = Type.Object({
  roadSegmentId: UuidSchema,
});

export const MovementScoreSchema = Type.Object({
  confidence: Type.Number({ maximum: 1, minimum: 0 }),
  confidenceLevel: ConfidenceLevelSchema,
  eventCount: Type.Integer({ minimum: 0 }),
  grade: RoadGradeSchema,
  movementType: MovementTypeSchema,
  score: Type.Union([Type.Integer({ maximum: 100, minimum: 0 }), Type.Null()]),
});
export type MovementScore = Static<typeof MovementScoreSchema>;

export const RoadDetailResponseSchema = Type.Object({
  eventCount: Type.Integer({ minimum: 0 }),
  lastDetectedAt: Type.Union([IsoDateSchema, Type.Null()]),
  latitude: LatitudeSchema,
  longitude: LongitudeSchema,
  recentEvents: Type.Array(
    Type.Object({
      detectedAt: IsoDateSchema,
      gpsAccuracy: Type.Number({ minimum: 0 }),
      impactLevel: ImpactLevelSchema,
      severity: Type.Number({ maximum: 1, minimum: 0 }),
    }),
  ),
  roadName: Type.String(),
  roadSegmentId: UuidSchema,
  scores: Type.Array(MovementScoreSchema),
  updatedAt: IsoDateSchema,
});
export type RoadDetailResponse = Static<typeof RoadDetailResponseSchema>;
