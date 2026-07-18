import cors from "@fastify/cors";
import sensible from "@fastify/sensible";
import swagger from "@fastify/swagger";
import swaggerUi from "@fastify/swagger-ui";
import { Type, type TypeBoxTypeProvider } from "@fastify/type-provider-typebox";
import Fastify, { type FastifyInstance } from "fastify";
import type { EventDeduplicator, RoadRepository } from "./data/repository.js";
import { DomainError } from "./domain/errors.js";
import { apiRoutes } from "./routes/index.js";
import { createServices } from "./services/index.js";

export interface BuildAppOptions {
  corsOrigins?: string[];
  deduplicator: EventDeduplicator;
  logger?: boolean | { level: string };
  publicPathPrefix?: string;
  repository: RoadRepository;
}

export function buildApp(options: BuildAppOptions): FastifyInstance {
  const publicPathPrefix = options.publicPathPrefix ?? "";
  const app = Fastify({
    logger: options.logger ?? false,
    trustProxy: true,
  }).withTypeProvider<TypeBoxTypeProvider>();
  const services = createServices(options.repository, options.deduplicator);

  void app.register(cors, {
    origin(origin, callback) {
      if (
        !origin ||
        !options.corsOrigins ||
        options.corsOrigins.includes(origin)
      ) {
        callback(null, true);
        return;
      }
      callback(new Error("Origin is not allowed"), false);
    },
  });
  void app.register(sensible);
  void app.register(swagger, {
    openapi: {
      info: {
        description:
          "익명 이동 센서 후보를 도로 구간별 접근성 데이터로 집계합니다.",
        title: "Road DNA API",
        version: "1.0.0",
      },
      servers: [{ url: `${publicPathPrefix}/api/v1` }],
    },
  });
  void app.register(swaggerUi, {
    indexPrefix: publicPathPrefix,
    routePrefix: "/docs",
    uiConfig: {
      docExpansion: "list",
      deepLinking: false,
    },
  });

  app.get(
    "/health",
    {
      schema: {
        response: {
          200: Type.Object({
            checks: Type.Object({
              database: Type.Boolean(),
              redis: Type.Boolean(),
            }),
            service: Type.Literal("road-dna-api"),
            status: Type.Union([Type.Literal("ok"), Type.Literal("degraded")]),
            timestamp: Type.String({ format: "date-time" }),
          }),
        },
        summary: "API, DB, Redis 상태 확인",
        tags: ["System"],
      },
    },
    async () => {
      const [database, redis] = await Promise.all([
        options.repository.ping(),
        options.deduplicator.ping(),
      ]);
      return {
        checks: { database, redis },
        service: "road-dna-api" as const,
        status: database && redis ? ("ok" as const) : ("degraded" as const),
        timestamp: new Date().toISOString(),
      };
    },
  );

  void app.register(apiRoutes(services), { prefix: "/api/v1" });

  app.setNotFoundHandler((request, reply) =>
    reply.code(404).send({
      code: "ROUTE_NOT_FOUND",
      message: "요청한 API 경로를 찾을 수 없어요.",
      requestId: request.id,
    }),
  );

  app.setErrorHandler((error, request, reply) => {
    if (error instanceof DomainError) {
      return reply.code(error.statusCode).send({
        code: error.code,
        message: error.message,
        requestId: request.id,
      });
    }
    if (
      typeof error === "object" &&
      error !== null &&
      "validation" in error &&
      error.validation
    ) {
      return reply.code(400).send({
        code: "VALIDATION_ERROR",
        message: "요청 값의 형식이나 범위를 확인해 주세요.",
        requestId: request.id,
      });
    }
    request.log.error({ err: error }, "Unhandled request error");
    return reply.code(500).send({
      code: "INTERNAL_ERROR",
      message: "서버에서 요청을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.",
      requestId: request.id,
    });
  });

  app.addHook("onClose", async () => {
    await Promise.all([
      options.repository.close(),
      options.deduplicator.close(),
    ]);
  });

  return app;
}
