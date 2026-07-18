import { RoutesQuerySchema, RoutesResponseSchema } from "@road-dna/contracts";
import type { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import type { Services } from "../services/index.js";

export function routeRoutes(services: Services): FastifyPluginAsyncTypebox {
  return async (app) => {
    app.get(
      "/routes",
      {
        schema: {
          querystring: RoutesQuerySchema,
          response: {
            200: RoutesResponseSchema,
          },
          summary: "빠른 경로와 Road DNA 접근성 경로 비교",
          tags: ["Routes"],
        },
      },
      async (request) => services.routes.routes(request.query),
    );
  };
}
