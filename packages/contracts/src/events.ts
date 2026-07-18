import { type Static, Type } from "@sinclair/typebox";
import {
  EventStatusSchema,
  ImpactLevelSchema,
  IsoDateSchema,
  LatitudeSchema,
  LongitudeSchema,
  MovementTypeSchema,
  UuidSchema,
} from "./common.js";

export const SessionEventParamsSchema = Type.Object({
  sessionId: UuidSchema,
});

export const SensorWindowSchema = Type.Object(
  {
    durationMs: Type.Integer({ maximum: 10_000, minimum: 500 }),
    maxPeak: Type.Number({ minimum: 0 }),
    mean: Type.Number(),
    peakCount: Type.Integer({ minimum: 0 }),
    rms: Type.Number({ minimum: 0 }),
    standardDeviation: Type.Number({ minimum: 0 }),
  },
  { additionalProperties: false },
);

export const CreateSensorEventRequestSchema = Type.Object(
  {
    anomalyScore: Type.Number({ maximum: 1, minimum: 0 }),
    detectedAt: IsoDateSchema,
    gpsAccuracy: Type.Number({ maximum: 500, minimum: 0 }),
    impactLevel: ImpactLevelSchema,
    latitude: LatitudeSchema,
    longitude: LongitudeSchema,
    movementType: MovementTypeSchema,
    peakValue: Type.Number({ minimum: 0 }),
    severity: Type.Number({ maximum: 1, minimum: 0 }),
    speed: Type.Optional(Type.Number({ maximum: 30, minimum: 0 })),
    window: Type.Optional(SensorWindowSchema),
  },
  { additionalProperties: false },
);
export type CreateSensorEventRequest = Static<
  typeof CreateSensorEventRequestSchema
>;

export const CreateSensorEventResponseSchema = Type.Object({
  eventId: UuidSchema,
  roadSegmentId: Type.Union([UuidSchema, Type.Null()]),
  status: EventStatusSchema,
});
export type CreateSensorEventResponse = Static<
  typeof CreateSensorEventResponseSchema
>;
