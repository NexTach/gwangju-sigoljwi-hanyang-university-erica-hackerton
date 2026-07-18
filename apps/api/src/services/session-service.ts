import type {
  CreateSessionRequest,
  EndSessionRequest,
  SessionResponse,
} from "@road-dna/contracts";
import type { RoadRepository } from "../data/repository.js";
import { DomainError } from "../domain/errors.js";

export class SessionService {
  constructor(private readonly repository: RoadRepository) {}

  async create(input: CreateSessionRequest): Promise<SessionResponse> {
    const startedAt = new Date(input.startedAt);
    if (startedAt.getTime() > Date.now() + 5 * 60_000) {
      throw new DomainError(
        "SESSION_START_IN_FUTURE",
        "측정 시작 시각이 현재 시각보다 너무 늦어요.",
        422,
      );
    }
    const session = await this.repository.createSession(input);
    return this.publicSession(session);
  }

  async end(
    sessionId: string,
    input: EndSessionRequest,
  ): Promise<SessionResponse> {
    const existing = await this.repository.getSession(sessionId);
    if (!existing) {
      throw new DomainError(
        "SESSION_NOT_FOUND",
        "측정 세션을 찾을 수 없어요.",
        404,
      );
    }
    if (existing.status !== "ACTIVE") {
      throw new DomainError(
        "SESSION_ALREADY_ENDED",
        "이미 종료된 측정 세션이에요.",
        409,
      );
    }
    if (new Date(input.endedAt) < new Date(existing.startedAt)) {
      throw new DomainError(
        "SESSION_END_BEFORE_START",
        "측정 종료 시각은 시작 시각보다 늦어야 해요.",
        422,
      );
    }
    const session = await this.repository.endSession(sessionId, input.endedAt);
    if (!session) {
      throw new DomainError(
        "SESSION_NOT_FOUND",
        "측정 세션을 찾을 수 없어요.",
        404,
      );
    }
    return this.publicSession(session);
  }

  private publicSession(session: {
    endedAt: string | null;
    movementType: SessionResponse["movementType"];
    sessionId: string;
    startedAt: string;
    status: SessionResponse["status"];
  }): SessionResponse {
    return {
      endedAt: session.endedAt,
      movementType: session.movementType,
      sessionId: session.sessionId,
      startedAt: session.startedAt,
      status: session.status,
    };
  }
}
