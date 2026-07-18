import { type Static, Type } from "@sinclair/typebox";
import {
  IsoDateSchema,
  MovementTypeSchema,
  SessionStatusSchema,
  UuidSchema,
} from "./common.js";

export const CreateSessionRequestSchema = Type.Object(
  {
    anonymousUserId: UuidSchema,
    appVersion: Type.Optional(Type.String({ maxLength: 32 })),
    deviceModel: Type.Optional(Type.String({ maxLength: 80 })),
    movementType: MovementTypeSchema,
    startedAt: IsoDateSchema,
  },
  { additionalProperties: false },
);
export type CreateSessionRequest = Static<typeof CreateSessionRequestSchema>;

export const SessionResponseSchema = Type.Object({
  endedAt: Type.Union([IsoDateSchema, Type.Null()]),
  movementType: MovementTypeSchema,
  sessionId: UuidSchema,
  startedAt: IsoDateSchema,
  status: SessionStatusSchema,
});
export type SessionResponse = Static<typeof SessionResponseSchema>;

export const EndSessionParamsSchema = Type.Object({
  sessionId: UuidSchema,
});

export const EndSessionRequestSchema = Type.Object(
  {
    endedAt: IsoDateSchema,
  },
  { additionalProperties: false },
);
export type EndSessionRequest = Static<typeof EndSessionRequestSchema>;
