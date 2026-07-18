import type {
  CreateSensorEventRequest,
  CreateSensorEventResponse,
  EventStatus,
} from "@road-dna/contracts";
import type { EventDeduplicator, RoadRepository } from "../data/repository.js";
import { classifyEvent } from "../domain/event-policy.js";
import { DomainError } from "../domain/errors.js";

export class EventService {
  constructor(
    private readonly repository: RoadRepository,
    private readonly deduplicator: EventDeduplicator,
  ) {}

  async create(
    sessionId: string,
    event: CreateSensorEventRequest,
  ): Promise<CreateSensorEventResponse> {
    const session = await this.repository.getSession(sessionId);
    if (!session) {
      throw new DomainError(
        "SESSION_NOT_FOUND",
        "측정 세션을 찾을 수 없어요.",
        404,
      );
    }
    if (session.status !== "ACTIVE") {
      throw new DomainError(
        "SESSION_NOT_ACTIVE",
        "종료된 세션에는 감지 이벤트를 추가할 수 없어요.",
        409,
      );
    }
    if (session.movementType !== event.movementType) {
      throw new DomainError(
        "MOVEMENT_TYPE_MISMATCH",
        "세션과 감지 이벤트의 이동 유형이 달라요.",
        422,
      );
    }

    let status: EventStatus = classifyEvent(event);
    if (
      status === "ACCEPTED" &&
      (await this.deduplicator.isDuplicate(sessionId, event))
    ) {
      status = "REJECTED_DUPLICATE";
    }

    const result = await this.repository.recordEvent(session, event, status);
    return {
      eventId: result.eventId,
      roadSegmentId: result.roadSegmentId,
      status,
    };
  }
}
