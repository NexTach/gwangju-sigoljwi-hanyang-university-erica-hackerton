import {
  DashboardOverviewQuerySchema,
  DashboardOverviewResponseSchema,
  PriorityRoadsQuerySchema,
  PriorityRoadsResponseSchema,
} from "@road-dna/contracts";
import type { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import type { Services } from "../services/index.js";

export function dashboardRoutes(services: Services): FastifyPluginAsyncTypebox {
  return async (app) => {
    app.get(
      "/dashboard/overview",
      {
        schema: {
          querystring: DashboardOverviewQuerySchema,
          response: {
            200: DashboardOverviewResponseSchema,
          },
          summary: "도시 접근성 핵심 지표",
          tags: ["Dashboard"],
        },
      },
      async (request) =>
        services.dashboard.overview(request.query.movementType),
    );

    app.get(
      "/dashboard/priorities",
      {
        schema: {
          querystring: PriorityRoadsQuerySchema,
          response: {
            200: PriorityRoadsResponseSchema,
          },
          summary: "접근성 개선 우선 도로",
          tags: ["Dashboard"],
        },
      },
      async (request) =>
        services.dashboard.priorities(
          request.query.limit,
          request.query.movementType,
        ),
    );
  };
}
