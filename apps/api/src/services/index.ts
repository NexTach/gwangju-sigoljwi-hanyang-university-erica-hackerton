import type { EventDeduplicator, RoadRepository } from "../data/repository.js";
import { DashboardService } from "./dashboard-service.js";
import { EventService } from "./event-service.js";
import { RoadService } from "./road-service.js";
import { RouteService } from "./route-service.js";
import { SessionService } from "./session-service.js";

export interface Services {
  dashboard: DashboardService;
  events: EventService;
  roads: RoadService;
  routes: RouteService;
  sessions: SessionService;
}

export function createServices(
  repository: RoadRepository,
  deduplicator: EventDeduplicator,
): Services {
  const roads = new RoadService(repository);
  return {
    dashboard: new DashboardService(repository),
    events: new EventService(repository, deduplicator),
    roads,
    routes: new RouteService(roads),
    sessions: new SessionService(repository),
  };
}
