import type {
  DashboardOverviewResponse,
  MovementType,
  PriorityRoadsResponse,
} from "@road-dna/contracts";
import type { RoadRepository } from "../data/repository.js";

export class DashboardService {
  constructor(private readonly repository: RoadRepository) {}

  overview(movementType?: MovementType): Promise<DashboardOverviewResponse> {
    return this.repository.getOverview(movementType);
  }

  async priorities(
    limit: number,
    movementType?: MovementType,
  ): Promise<PriorityRoadsResponse> {
    return {
      roads: await this.repository.getPriorityRoads(limit, movementType),
    };
  }
}
