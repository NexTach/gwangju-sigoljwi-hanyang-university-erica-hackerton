import {
  ErrorResponseSchema,
  NearbyRoadsQuerySchema,
  NearbyRoadsResponseSchema,
  RoadDetailParamsSchema,
  RoadDetailResponseSchema,
} from "@road-dna/contracts";
import type { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import type { Services } from "../services/index.js";

export function roadRoutes(services: Services): FastifyPluginAsyncTypebox {
  return async (app) => {
    app.get(
      "/roads/nearby",
      {
        schema: {
          querystring: NearbyRoadsQuerySchema,
          response: {
            200: NearbyRoadsResponseSchema,
          },
          summary: "현재 위치 주변 Road DNA 도로 조회",
          tags: ["Roads"],
        },
      },
      async (request) => services.roads.nearby(request.query),
    );

    app.get(
      "/roads/:roadSegmentId",
      {
        schema: {
          params: RoadDetailParamsSchema,
          response: {
            200: RoadDetailResponseSchema,
            404: ErrorResponseSchema,
          },
          summary: "도로 구간 상세와 이동 유형별 점수 조회",
          tags: ["Roads"],
        },
      },
      async (request) => services.roads.detail(request.params.roadSegmentId),
    );
  };
}
