import type {
  MovementType,
  NearbyRoadsQuery,
  NearbyRoadsResponse,
  RoadDetailResponse,
} from "@road-dna/contracts";
import type { RoadRepository } from "../data/repository.js";
import { DomainError } from "../domain/errors.js";

export class RoadService {
  constructor(private readonly repository: RoadRepository) {}

  async nearby(query: NearbyRoadsQuery): Promise<NearbyRoadsResponse> {
    return { roads: await this.repository.nearbyRoads(query) };
  }

  async detail(roadSegmentId: string): Promise<RoadDetailResponse> {
    const road = await this.repository.getRoadDetail(roadSegmentId);
    if (!road) {
      throw new DomainError(
        "ROAD_NOT_FOUND",
        "도로 구간을 찾을 수 없어요.",
        404,
      );
    }
    return road;
  }

  async nearbyForRoute(input: {
    latitude: number;
    longitude: number;
    movementType: MovementType;
    radius: number;
  }) {
    return this.repository.nearbyRoads({
      ...input,
      radius: Math.min(2000, Math.max(5, input.radius)),
    });
  }
}
