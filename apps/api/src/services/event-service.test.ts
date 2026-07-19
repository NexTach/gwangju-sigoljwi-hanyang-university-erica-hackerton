import type { CreateSensorEventRequest } from "@road-dna/contracts";
import { describe, expect, it, vi } from "vitest";
import type {
  EventDeduplicator,
  RoadRepository,
  StoredSession,
} from "../data/repository.js";
import { EventService } from "./event-service.js";

const activeSession: StoredSession = {
  anonymousUserId: "d189be1f-e2d5-4b90-8cec-360ec343be99",
  endedAt: null,
  movementType: "WHEELCHAIR",
  sessionId: "20000000-0000-4000-8000-000000000001",
  startedAt: "2026-07-19T00:00:00.000Z",
  status: "ACTIVE",
};

const event = (
  overrides: Partial<CreateSensorEventRequest> = {},
): CreateSensorEventRequest => ({
  anomalyScore: 0.8,
  detectedAt: "2026-07-19T00:00:01.000Z",
  gpsAccuracy: 5,
  impactLevel: "HIGH_IMPACT",
  latitude: 35.1786,
  longitude: 126.9007,
  movementType: "WHEELCHAIR",
  peakValue: 6,
  severity: 0.8,
  speed: 1,
  window: {
    durationMs: 2_000,
    maxPeak: 6,
    mean: 1.2,
    peakCount: 3,
    rms: 2,
    standardDeviation: 0.8,
  },
  ...overrides,
});

describe("Describe EventService.create", () => {
  describe("Context 존재하지 않는 세션으로 이벤트를 만드는 경우", () => {
    it("It 이벤트를 저장하지 않고 찾기 오류를 반환한다", async () => {
      const recordEvent = vi.fn<RoadRepository["recordEvent"]>();
      const service = new EventService(
        {
          getSession: vi
            .fn<RoadRepository["getSession"]>()
            .mockResolvedValue(null),
          recordEvent,
        } as unknown as RoadRepository,
        {
          isDuplicate: vi.fn<EventDeduplicator["isDuplicate"]>(),
        } as unknown as EventDeduplicator,
      );

      await expect(
        service.create(activeSession.sessionId, event()),
      ).rejects.toMatchObject({
        code: "SESSION_NOT_FOUND",
        statusCode: 404,
      });
      expect(recordEvent).not.toHaveBeenCalled();
    });
  });

  describe("Context 세션과 이벤트의 이동 유형이 다른 경우", () => {
    it("It 이벤트를 저장하지 않고 검증 오류를 반환한다", async () => {
      const recordEvent = vi.fn<RoadRepository["recordEvent"]>();
      const service = new EventService(
        {
          getSession: vi
            .fn<RoadRepository["getSession"]>()
            .mockResolvedValue(activeSession),
          recordEvent,
        } as unknown as RoadRepository,
        {
          isDuplicate: vi.fn<EventDeduplicator["isDuplicate"]>(),
        } as unknown as EventDeduplicator,
      );

      await expect(
        service.create(
          activeSession.sessionId,
          event({ movementType: "WALKING" }),
        ),
      ).rejects.toMatchObject({
        code: "MOVEMENT_TYPE_MISMATCH",
        statusCode: 422,
      });
      expect(recordEvent).not.toHaveBeenCalled();
    });
  });

  describe("Context 승인 가능한 이벤트가 중복으로 감지된 경우", () => {
    it("It 중복 상태로 한 번만 저장하고 영수증을 반환한다", async () => {
      const recordEvent = vi
        .fn<RoadRepository["recordEvent"]>()
        .mockResolvedValue({
          eventId: "30000000-0000-4000-8000-000000000001",
          roadSegmentId: "10000000-0000-4000-8000-000000000001",
        });
      const isDuplicate = vi
        .fn<EventDeduplicator["isDuplicate"]>()
        .mockResolvedValue(true);
      const service = new EventService(
        {
          getSession: vi
            .fn<RoadRepository["getSession"]>()
            .mockResolvedValue(activeSession),
          recordEvent,
        } as unknown as RoadRepository,
        { isDuplicate } as unknown as EventDeduplicator,
      );
      const candidate = event();

      await expect(
        service.create(activeSession.sessionId, candidate),
      ).resolves.toEqual({
        eventId: "30000000-0000-4000-8000-000000000001",
        roadSegmentId: "10000000-0000-4000-8000-000000000001",
        status: "REJECTED_DUPLICATE",
      });
      expect(recordEvent).toHaveBeenCalledWith(
        activeSession,
        candidate,
        "REJECTED_DUPLICATE",
      );
    });
  });
});
