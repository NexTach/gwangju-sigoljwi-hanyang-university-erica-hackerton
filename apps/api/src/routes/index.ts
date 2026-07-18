import type { FastifyPluginAsyncTypebox } from "@fastify/type-provider-typebox";
import type { Services } from "../services/index.js";
import { dashboardRoutes } from "./dashboard.js";
import { eventRoutes } from "./events.js";
import { roadRoutes } from "./roads.js";
import { routeRoutes } from "./routes.js";
import { sessionRoutes } from "./sessions.js";

export function apiRoutes(services: Services): FastifyPluginAsyncTypebox {
  return async (app) => {
    await app.register(sessionRoutes(services));
    await app.register(eventRoutes(services));
    await app.register(roadRoutes(services));
    await app.register(routeRoutes(services));
    await app.register(dashboardRoutes(services));
  };
}
