import type { RoadMapItem, RoutesQuery } from "@road-dna/contracts";
import { describe, expect, it, vi } from "vitest";
import { RoadService } from "./road-service.js";
import { RouteService } from "./route-service.js";

const query: RoutesQuery = {
  destinationLat: 35.1798,
  destinationLng: 126.902,
  movementType: "WHEELCHAIR",
  originLat: 35.1786,
  originLng: 126.9007,
};

const road = (
  score: number,
  overrides: Partial<RoadMapItem> = {},
): RoadMapItem => ({
  confidence: 1,
  confidenceLevel: "HIGH",
  eventCount: 10,
  grade: "CAUTION",
  latitude: 35.179,
  longitude: 126.901,
  movementType: "WHEELCHAIR",
  roadName: "테스트 도로",
  roadSegmentId: "10000000-0000-4000-8000-000000000001",
  score,
  updatedAt: "2026-07-19T00:00:00.000Z",
  ...overrides,
});

describe("Describe RouteService.routes", () => {
  describe("Context 주변에 점수가 있는 도로가 없는 경우", () => {
    it("It 거리 기반 경로와 알 수 없는 접근성 점수를 반환한다", async () => {
      const nearbyForRoute = vi
        .fn<RoadService["nearbyForRoute"]>()
        .mockResolvedValue([]);
      const service = new RouteService({
        nearbyForRoute,
      } as unknown as RoadService);

      const result = await service.routes(query);

      expect(result.routes).toHaveLength(2);
      expect(result.routes).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            accessibilityScore: null,
            source: "MVP_ESTIMATE",
            type: "FASTEST",
          }),
          expect.objectContaining({
            accessibilityScore: null,
            source: "MVP_ESTIMATE",
            type: "ACCESSIBLE",
          }),
        ]),
      );
    });
  });

  describe("Context 주변 도로에 신뢰 가능한 점수가 있는 경우", () => {
    it("It 가중 점수와 최선 점수를 경로 선택지에 반영한다", async () => {
      const nearbyForRoute = vi
        .fn<RoadService["nearbyForRoute"]>()
        .mockResolvedValue([
          road(40),
          road(80, {
            roadSegmentId: "10000000-0000-4000-8000-000000000002",
          }),
        ]);
      const service = new RouteService({
        nearbyForRoute,
      } as unknown as RoadService);

      const result = await service.routes(query);

      expect(result.routes[0]).toMatchObject({
        accessibilityScore: 60,
        source: "ROAD_DNA",
        type: "FASTEST",
      });
      expect(result.routes[1]).toMatchObject({
        accessibilityScore: 80,
        source: "ROAD_DNA",
        type: "ACCESSIBLE",
      });
      expect(result.routes[1]?.geometry).toHaveLength(3);
    });
  });
});
