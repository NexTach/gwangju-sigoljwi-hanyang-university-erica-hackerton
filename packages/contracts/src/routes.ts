import { type Static, Type } from "@sinclair/typebox";
import {
  LatitudeSchema,
  LongitudeSchema,
  MovementTypeSchema,
} from "./common.js";

export const RoutesQuerySchema = Type.Object(
  {
    destinationLat: LatitudeSchema,
    destinationLng: LongitudeSchema,
    movementType: MovementTypeSchema,
    originLat: LatitudeSchema,
    originLng: LongitudeSchema,
  },
  { additionalProperties: false },
);
export type RoutesQuery = Static<typeof RoutesQuerySchema>;

export const RouteOptionSchema = Type.Object({
  accessibilityScore: Type.Union([
    Type.Integer({ maximum: 100, minimum: 0 }),
    Type.Null(),
  ]),
  distance: Type.Integer({ minimum: 0 }),
  duration: Type.Integer({ minimum: 0 }),
  geometry: Type.Array(Type.Tuple([LongitudeSchema, LatitudeSchema]), {
    minItems: 2,
  }),
  source: Type.Union([Type.Literal("ROAD_DNA"), Type.Literal("MVP_ESTIMATE")]),
  type: Type.Union([Type.Literal("FASTEST"), Type.Literal("ACCESSIBLE")]),
});
export type RouteOption = Static<typeof RouteOptionSchema>;

export const RoutesResponseSchema = Type.Object({
  disclaimer: Type.String(),
  routes: Type.Array(RouteOptionSchema, { maxItems: 3, minItems: 1 }),
});
export type RoutesResponse = Static<typeof RoutesResponseSchema>;
