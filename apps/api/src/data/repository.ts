import type {
  CreateSensorEventRequest,
  CreateSessionRequest,
  DashboardOverviewResponse,
  EventStatus,
  MovementType,
  NearbyRoadsQuery,
  PriorityRoad,
  RoadDetailResponse,
  RoadMapItem,
  SessionResponse,
} from "@road-dna/contracts";

export interface StoredSession extends SessionResponse {
  anonymousUserId: string;
}

export interface RecordEventResult {
  eventId: string;
  roadSegmentId: string | null;
}

export interface RoadRepository {
  close(): Promise<void>;
  createSession(input: CreateSessionRequest): Promise<StoredSession>;
  endSession(sessionId: string, endedAt: string): Promise<StoredSession | null>;
  getOverview(movementType?: MovementType): Promise<DashboardOverviewResponse>;
  getPriorityRoads(
    limit: number,
    movementType?: MovementType,
  ): Promise<PriorityRoad[]>;
  getRoadDetail(roadSegmentId: string): Promise<RoadDetailResponse | null>;
  getSession(sessionId: string): Promise<StoredSession | null>;
  nearbyRoads(query: NearbyRoadsQuery): Promise<RoadMapItem[]>;
  ping(): Promise<boolean>;
  recordEvent(
    session: StoredSession,
    event: CreateSensorEventRequest,
    status: EventStatus,
  ): Promise<RecordEventResult>;
}

export interface EventDeduplicator {
  close(): Promise<void>;
  isDuplicate(
    sessionId: string,
    event: CreateSensorEventRequest,
  ): Promise<boolean>;
  ping(): Promise<boolean>;
}
