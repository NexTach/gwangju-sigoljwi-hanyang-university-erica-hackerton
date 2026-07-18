import type { Pool } from "mysql2/promise";
import { describe, expect, it, vi } from "vitest";
import { MysqlRoadRepository } from "./mysql-repository.js";

describe("MysqlRoadRepository", () => {
  it("uses an escaped text query for priority LIMIT values", async () => {
    const query = vi.fn().mockResolvedValue([
      [
        {
          confidence: 0.82,
          confidence_level: "HIGH",
          event_count: 14,
          grade: "CAUTION",
          latitude: 35.15995,
          longitude: 126.85315,
          movement_type: "WHEELCHAIR",
          road_name: "상무중앙로",
          road_segment_id: "123e4567-e89b-42d3-a456-426614174000",
          score: 58,
          updated_at: "2026-07-18 08:00:00",
        },
      ],
    ]);
    const execute = vi.fn(() => {
      throw new Error("prepared LIMIT bindings are incompatible");
    });
    const repository = new MysqlRoadRepository({
      execute,
      query,
    } as unknown as Pool);

    const roads = await repository.getPriorityRoads(20);

    expect(execute).not.toHaveBeenCalled();
    expect(query).toHaveBeenCalledOnce();
    expect(query.mock.calls[0]?.[0]).toContain("LIMIT :limit");
    expect(query.mock.calls[0]?.[1]).toEqual({
      limit: 20,
      movementType: null,
    });
    expect(roads).toEqual([
      expect.objectContaining({
        confidence: 0.82,
        roadName: "상무중앙로",
        score: 58,
      }),
    ]);
  });
});
