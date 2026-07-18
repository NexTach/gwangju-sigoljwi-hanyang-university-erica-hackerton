import {
  CreateSensorEventRequestSchema,
  CreateSensorEventResponseSchema,
  ErrorResponseSchema,
  SessionEventParamsSchema,
} from "@road-dna/contracts";
import type { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import type { Services } from "../services/index.js";

export function eventRoutes(services: Services): FastifyPluginAsyncTypebox {
  return async (app) => {
    app.post(
      "/sessions/:sessionId/events",
      {
        schema: {
          body: CreateSensorEventRequestSchema,
          params: SessionEventParamsSchema,
          response: {
            201: CreateSensorEventResponseSchema,
            404: ErrorResponseSchema,
            409: ErrorResponseSchema,
            422: ErrorResponseSchema,
          },
          summary: "이상 이동 충격 후보 등록",
          tags: ["Events"],
        },
      },
      async (request, reply) => {
        const event = await services.events.create(
          request.params.sessionId,
          request.body,
        );
        return reply.code(201).send(event);
      },
    );
  };
}
