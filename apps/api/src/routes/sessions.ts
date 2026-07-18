import {
  CreateSessionRequestSchema,
  EndSessionParamsSchema,
  EndSessionRequestSchema,
  ErrorResponseSchema,
  SessionResponseSchema,
} from "@road-dna/contracts";
import type { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import type { Services } from "../services/index.js";

export function sessionRoutes(services: Services): FastifyPluginAsyncTypebox {
  return async (app) => {
    app.post(
      "/sessions",
      {
        schema: {
          body: CreateSessionRequestSchema,
          response: {
            201: SessionResponseSchema,
            422: ErrorResponseSchema,
          },
          summary: "이동 측정 세션 생성",
          tags: ["Sessions"],
        },
      },
      async (request, reply) => {
        const session = await services.sessions.create(request.body);
        return reply.code(201).send(session);
      },
    );

    app.patch(
      "/sessions/:sessionId/end",
      {
        schema: {
          body: EndSessionRequestSchema,
          params: EndSessionParamsSchema,
          response: {
            200: SessionResponseSchema,
            404: ErrorResponseSchema,
            409: ErrorResponseSchema,
            422: ErrorResponseSchema,
          },
          summary: "이동 측정 세션 종료",
          tags: ["Sessions"],
        },
      },
      async (request) =>
        services.sessions.end(request.params.sessionId, request.body),
    );
  };
}
