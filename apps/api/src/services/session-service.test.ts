import type {
  CreateSessionRequest,
  SessionResponse,
} from "@road-dna/contracts";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { RoadRepository, StoredSession } from "../data/repository.js";
import { SessionService } from "./session-service.js";

const activeSession: StoredSession = {
  anonymousUserId: "d189be1f-e2d5-4b90-8cec-360ec343be99",
  endedAt: null,
  movementType: "WHEELCHAIR",
  sessionId: "20000000-0000-4000-8000-000000000001",
  startedAt: "2026-07-19T00:00:00.000Z",
  status: "ACTIVE",
};

const createInput = (
  overrides: Partial<CreateSessionRequest> = {},
): CreateSessionRequest => ({
  anonymousUserId: activeSession.anonymousUserId,
  movementType: activeSession.movementType,
  startedAt: activeSession.startedAt,
  ...overrides,
});

afterEach(() => {
  vi.useRealTimers();
});

describe("Describe SessionService", () => {
  describe("Context 시작 시각이 현재보다 5분 넘게 미래인 경우", () => {
    it("It 세션을 저장하지 않고 검증 오류를 반환한다", async () => {
      vi.useFakeTimers();
      vi.setSystemTime("2026-07-19T00:00:00.000Z");
      const createSession = vi.fn<RoadRepository["createSession"]>();
      const service = new SessionService({
        createSession,
      } as unknown as RoadRepository);

      await expect(
        service.create(createInput({ startedAt: "2026-07-19T00:05:00.001Z" })),
      ).rejects.toMatchObject({
        code: "SESSION_START_IN_FUTURE",
        statusCode: 422,
      });
      expect(createSession).not.toHaveBeenCalled();
    });
  });

  describe("Context 이미 종료된 세션을 다시 종료하는 경우", () => {
    it("It 저장소를 갱신하지 않고 충돌 오류를 반환한다", async () => {
      const getSession = vi
        .fn<RoadRepository["getSession"]>()
        .mockResolvedValue({
          ...activeSession,
          endedAt: "2026-07-19T00:10:00.000Z",
          status: "COMPLETED",
        });
      const endSession = vi.fn<RoadRepository["endSession"]>();
      const service = new SessionService({
        endSession,
        getSession,
      } as unknown as RoadRepository);

      await expect(
        service.end(activeSession.sessionId, {
          endedAt: "2026-07-19T00:20:00.000Z",
        }),
      ).rejects.toMatchObject({
        code: "SESSION_ALREADY_ENDED",
        statusCode: 409,
      });
      expect(endSession).not.toHaveBeenCalled();
    });
  });

  describe("Context 활성 세션을 유효한 시각에 종료하는 경우", () => {
    it("It 종료된 공개 세션을 반환한다", async () => {
      const endedAt = "2026-07-19T00:10:00.000Z";
      const endedSession: StoredSession = {
        ...activeSession,
        endedAt,
        status: "COMPLETED",
      };
      const getSession = vi
        .fn<RoadRepository["getSession"]>()
        .mockResolvedValue(activeSession);
      const endSession = vi
        .fn<RoadRepository["endSession"]>()
        .mockResolvedValue(endedSession);
      const service = new SessionService({
        endSession,
        getSession,
      } as unknown as RoadRepository);
      const expected: SessionResponse = {
        endedAt,
        movementType: "WHEELCHAIR",
        sessionId: activeSession.sessionId,
        startedAt: activeSession.startedAt,
        status: "COMPLETED",
      };

      await expect(
        service.end(activeSession.sessionId, { endedAt }),
      ).resolves.toEqual(expected);
      expect(endSession).toHaveBeenCalledWith(activeSession.sessionId, endedAt);
    });
  });
});
