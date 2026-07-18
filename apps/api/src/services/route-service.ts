import type {
  RouteOption,
  RoutesQuery,
  RoutesResponse,
} from "@road-dna/contracts";
import { distanceMeters, offsetMidpoint } from "../domain/geo.js";
import { RoadService } from "./road-service.js";

const routeDurationSeconds = (distance: number, multiplier = 1): number =>
  Math.round((distance / 1.05) * multiplier);

const scoreForRoads = (
  roads: Array<{ confidence: number; score: number | null }>,
): number | null => {
  const known = roads.filter(
    (road): road is { confidence: number; score: number } =>
      road.score !== null,
  );
  if (known.length === 0) return null;
  const weighted = known.reduce(
    (state, road) => ({
      denominator: state.denominator + Math.max(road.confidence, 0.2),
      numerator: state.numerator + road.score * Math.max(road.confidence, 0.2),
    }),
    { denominator: 0, numerator: 0 },
  );
  return Math.round(weighted.numerator / weighted.denominator);
};

export class RouteService {
  constructor(private readonly roadService: RoadService) {}

  async routes(query: RoutesQuery): Promise<RoutesResponse> {
    const origin = {
      latitude: query.originLat,
      longitude: query.originLng,
    };
    const destination = {
      latitude: query.destinationLat,
      longitude: query.destinationLng,
    };
    const directDistance = Math.round(distanceMeters(origin, destination));
    const midpoint = {
      latitude: (origin.latitude + destination.latitude) / 2,
      longitude: (origin.longitude + destination.longitude) / 2,
    };
    const searchRadius = Math.min(2000, Math.max(100, directDistance / 2));
    const roads = await this.roadService.nearbyForRoute({
      ...midpoint,
      movementType: query.movementType,
      radius: searchRadius,
    });
    const fastestScore = scoreForRoads(roads);
    const offset = offsetMidpoint(
      origin,
      destination,
      Math.min(80, Math.max(24, directDistance * 0.08)),
    );
    const accessibleDistance = Math.round(
      distanceMeters(origin, offset) + distanceMeters(offset, destination),
    );
    const bestKnownScore =
      roads
        .map((road) => road.score)
        .filter((score): score is number => score !== null)
        .sort((first, second) => second - first)[0] ?? null;
    const accessibleScore =
      bestKnownScore === null
        ? null
        : Math.min(100, Math.max(bestKnownScore, (fastestScore ?? 0) + 12));
    const source = roads.some((road) => road.score !== null)
      ? "ROAD_DNA"
      : "MVP_ESTIMATE";

    const fastest: RouteOption = {
      accessibilityScore: fastestScore,
      distance: directDistance,
      duration: routeDurationSeconds(directDistance),
      geometry: [
        [origin.longitude, origin.latitude],
        [destination.longitude, destination.latitude],
      ],
      source,
      type: "FASTEST",
    };
    const accessible: RouteOption = {
      accessibilityScore: accessibleScore,
      distance: accessibleDistance,
      duration: routeDurationSeconds(accessibleDistance, 1.05),
      geometry: [
        [origin.longitude, origin.latitude],
        [offset.longitude, offset.latitude],
        [destination.longitude, destination.latitude],
      ],
      source,
      type: "ACCESSIBLE",
    };

    return {
      disclaimer:
        source === "ROAD_DNA"
          ? "Road DNA MVP 내부 지표를 반영한 비교이며, 검증된 접근성 표준 경로가 아닙니다."
          : "주변 Road DNA 데이터가 없어 거리 기반 시연 경로를 표시합니다.",
      routes: [fastest, accessible],
    };
  }
}
