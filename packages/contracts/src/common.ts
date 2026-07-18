import { type Static, Type } from "@sinclair/typebox";

export const MovementTypeSchema = Type.Union(
  [
    Type.Literal("WHEELCHAIR"),
    Type.Literal("STROLLER"),
    Type.Literal("WALKING"),
  ],
  { $id: "MovementType" },
);
export type MovementType = Static<typeof MovementTypeSchema>;

export const SessionStatusSchema = Type.Union([
  Type.Literal("ACTIVE"),
  Type.Literal("COMPLETED"),
  Type.Literal("CANCELLED"),
]);
export type SessionStatus = Static<typeof SessionStatusSchema>;

export const EventStatusSchema = Type.Union([
  Type.Literal("ACCEPTED"),
  Type.Literal("HELD_LOW_GPS_ACCURACY"),
  Type.Literal("HELD_DROP_PATTERN"),
  Type.Literal("REJECTED_STATIONARY"),
  Type.Literal("REJECTED_DUPLICATE"),
  Type.Literal("REJECTED_BELOW_THRESHOLD"),
]);
export type EventStatus = Static<typeof EventStatusSchema>;

export const ImpactLevelSchema = Type.Union([
  Type.Literal("LOW_IMPACT"),
  Type.Literal("MEDIUM_IMPACT"),
  Type.Literal("HIGH_IMPACT"),
]);
export type ImpactLevel = Static<typeof ImpactLevelSchema>;

export const RoadGradeSchema = Type.Union([
  Type.Literal("GOOD"),
  Type.Literal("NORMAL"),
  Type.Literal("CAUTION"),
  Type.Literal("POOR"),
  Type.Literal("UNKNOWN"),
]);
export type RoadGrade = Static<typeof RoadGradeSchema>;

export const ConfidenceLevelSchema = Type.Union([
  Type.Literal("LOW"),
  Type.Literal("MEDIUM"),
  Type.Literal("HIGH"),
]);
export type ConfidenceLevel = Static<typeof ConfidenceLevelSchema>;

// Keep the wire contracts self-validating in TypeBox as well as Fastify/Ajv.
// TypeBox's standalone Value.Check does not install format validators.
export const IsoDateSchema = Type.String({
  // JavaScript serializes milliseconds while Dart may serialize microseconds.
  // Accept both standard UTC representations at the API boundary.
  pattern: "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{1,6})?Z$",
});
export const UuidSchema = Type.String({
  pattern:
    "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$",
});
export const LatitudeSchema = Type.Number({ maximum: 90, minimum: -90 });
export const LongitudeSchema = Type.Number({ maximum: 180, minimum: -180 });

export const ErrorResponseSchema = Type.Object(
  {
    code: Type.String(),
    message: Type.String(),
    requestId: Type.String(),
  },
  { additionalProperties: false },
);
export type ErrorResponse = Static<typeof ErrorResponseSchema>;

export const PaginationSchema = Type.Object({
  limit: Type.Integer({ maximum: 100, minimum: 1 }),
  offset: Type.Integer({ minimum: 0 }),
  total: Type.Integer({ minimum: 0 }),
});
export type Pagination = Static<typeof PaginationSchema>;
