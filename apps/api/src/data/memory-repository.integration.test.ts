import { randomUUID } from "node:crypto";
import type {
  CreateSensorEventRequest,
  MovementType,
} from "@road-dna/contracts";
import { describe, expect, it } from "vitest";
import {
  seedYongbongScenario,
  yongbongCenter,
  yongbongRoadProfiles,
} from "../support/yongbong-scenario.js";
import { MemoryRoadRepository } from "./memory-repository.js";

const eventAt = (
  latitude: number,
  longitude: number,
  movementType: MovementType,
  roadSegmentIdHint?: string,
): CreateSensorEventRequest => ({
  anomalyScore: 0.82,
  detectedAt: new Date().toISOString(),
  gpsAccuracy: 4.2,
  impactLevel: "HIGH_IMPACT",
  latitude,
  longitude,
  movementType,
  peakValue: 5.6,
  roadSegmentIdHint,
  severity: 0.72,
  speed: 1.05,
  window: {
    durationMs: 2_000,
    maxPeak: 5.6,
    mean: 1.02,
    peakCount: 3,
    rms: 3.1,
    standardDeviation: 0.9,
  },
});

const createSession = (
  repository: MemoryRoadRepository,
  movementType: MovementType = "WHEELCHAIR",
) =>
  repository.createSession({
    anonymousUserId: randomUUID(),
    movementType,
    startedAt: new Date().toISOString(),
  });

describe("Describe 용봉동 시나리오 저장소", () => {
  describe("Context 비어 있는 저장소를 두 번 동기화한 경우", () => {
    it("It 첫 실행에만 8개 도로와 기준 이벤트를 채운다", async () => {
      const repository = new MemoryRoadRepository();

      const first = await seedYongbongScenario(repository);
      const second = await seedYongbongScenario(repository);
      const nearby = await repository.nearbyRoads({
        ...yongbongCenter,
        movementType: "WHEELCHAIR",
        radius: 2_000,
      });
      const overview = await repository.getOverview();

      expect(first).toEqual({ eventCount: 342, sessionCount: 24 });
      expect(second).toEqual({ eventCount: 0, sessionCount: 0 });
      expect(nearby).toHaveLength(8);
      expect(nearby.map((road) => road.roadName).sort()).toEqual(
        yongbongRoadProfiles.map((road) => road.roadName).sort(),
      );
      expect(
        nearby
          .map((road) => road.score)
          .sort((first, second) => first! - second!),
      ).toEqual([39, 48, 59, 76, 83, 84, 86, 92]);
      expect(overview.roadCount).toBe(8);
      expect(overview.acceptedEventCount).toBe(342);
      expect(overview.unknownRoadCount).toBe(0);
    });
  });

  describe("Context 다른 지역의 기존 데이터가 있는 경우", () => {
    it("It 데이터를 보존하지만 용봉동 집계와 우선순위에서는 제외한다", async () => {
      const repository = new MemoryRoadRepository();
      const legacySession = await createSession(repository);
      await repository.recordEvent(
        legacySession,
        eventAt(35.1603, 126.8537, "WHEELCHAIR"),
        "ACCEPTED",
      );
      await seedYongbongScenario(repository);

      const overview = await repository.getOverview();
      const priorities = await repository.getPriorityRoads(100);

      expect(overview.acceptedEventCount).toBe(342);
      expect(overview.roadCount).toBe(8);
      expect(priorities).toHaveLength(24);
      expect(
        priorities.every((road) =>
          road.roadSegmentId.startsWith("10000000-0000-4000-8000-"),
        ),
      ).toBe(true);
    });
  });

  describe("Context 검증된 도로 힌트로 이벤트를 저장하는 경우", () => {
    it("It 고정 ID와 실제 도로명을 유지한다", async () => {
      const repository = new MemoryRoadRepository();
      const road = yongbongRoadProfiles[2]!;
      const session = await createSession(repository);
      const location = road.geometry[1]!;

      const receipt = await repository.recordEvent(
        session,
        eventAt(
          location.latitude,
          location.longitude,
          "WHEELCHAIR",
          road.roadSegmentId,
        ),
        "ACCEPTED",
      );
      const detail = await repository.getRoadDetail(road.roadSegmentId);

      expect(receipt.roadSegmentId).toBe(road.roadSegmentId);
      expect(detail?.roadName).toBe("설죽로202번길");
      expect(detail?.eventCount).toBe(1);
    });
  });

  describe("Context 임의 UUID를 도로 힌트로 보내는 경우", () => {
    it("It 임의 ID 대신 서버가 생성한 구간에 저장한다", async () => {
      const repository = new MemoryRoadRepository();
      const arbitraryId = "d189be1f-e2d5-4b90-8cec-360ec343be99";
      const road = yongbongRoadProfiles[2]!;
      const session = await createSession(repository);

      const receipt = await repository.recordEvent(
        session,
        eventAt(road.latitude, road.longitude, "WHEELCHAIR", arbitraryId),
        "ACCEPTED",
      );

      expect(receipt.roadSegmentId).not.toBe(arbitraryId);
      expect(await repository.getRoadDetail(arbitraryId)).toBeNull();
    });
  });
});
