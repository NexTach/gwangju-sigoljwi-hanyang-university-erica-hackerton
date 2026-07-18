import { randomUUID } from "node:crypto";
import type {
  CreateSensorEventRequest,
  CreateSessionRequest,
  DashboardOverviewResponse,
  EventStatus,
  MovementScore,
  MovementType,
  NearbyRoadsQuery,
  PriorityRoad,
  RoadDetailResponse,
  RoadMapItem,
} from "@road-dna/contracts";
import { distanceMeters } from "../domain/geo.js";
import {
  calculateRoadScore,
  type RoadAggregate,
  type RoadScoreResult,
} from "../domain/scoring.js";
import {
  isWithinYongbongBounds,
  matchYongbongRoadHint,
} from "../support/yongbong-scenario.js";
import type {
  RecordEventResult,
  RoadRepository,
  RoadSegmentSeed,
  StoredSession,
} from "./repository.js";

interface MemoryRoad {
  latitude: number;
  longitude: number;
  roadName: string;
  roadSegmentId: string;
  updatedAt: string;
}

interface MemoryEvent {
  anonymousUserId: string;
  detectedAt: string;
  event: CreateSensorEventRequest;
  roadSegmentId: string | null;
  status: EventStatus;
}

const movementTypes: MovementType[] = ["WHEELCHAIR", "STROLLER", "WALKING"];

export class MemoryRoadRepository implements RoadRepository {
  private readonly events: MemoryEvent[] = [];
  private readonly roads = new Map<string, MemoryRoad>();
  private readonly sessions = new Map<string, StoredSession>();
  private readonly traversals = new Map<string, Set<string>>();

  async close(): Promise<void> {}

  async createSession(input: CreateSessionRequest): Promise<StoredSession> {
    const session: StoredSession = {
      anonymousUserId: input.anonymousUserId,
      endedAt: null,
      movementType: input.movementType,
      sessionId: randomUUID(),
      startedAt: input.startedAt,
      status: "ACTIVE",
    };
    this.sessions.set(session.sessionId, session);
    return structuredClone(session);
  }

  async endSession(
    sessionId: string,
    endedAt: string,
  ): Promise<StoredSession | null> {
    const session = this.sessions.get(sessionId);
    if (!session) return null;
    const completed: StoredSession = {
      ...session,
      endedAt,
      status: "COMPLETED",
    };
    this.sessions.set(sessionId, completed);
    return structuredClone(completed);
  }

  async getSession(sessionId: string): Promise<StoredSession | null> {
    const session = this.sessions.get(sessionId);
    return session ? structuredClone(session) : null;
  }

  async recordEvent(
    session: StoredSession,
    event: CreateSensorEventRequest,
    status: EventStatus,
  ): Promise<RecordEventResult> {
    const eventId = randomUUID();
    let roadSegmentId: string | null = null;

    if (status === "ACCEPTED") {
      const hintedRoad = matchYongbongRoadHint(event);
      if (hintedRoad) await this.upsertRoadSegments([hintedRoad]);
      const existing = hintedRoad
        ? this.roads.get(hintedRoad.roadSegmentId)
        : [...this.roads.values()]
            .map((road) => ({
              distance: distanceMeters(road, event),
              road,
            }))
            .filter(({ distance }) => distance <= 10)
            .sort((first, second) => first.distance - second.distance)[0]?.road;

      const road =
        existing ??
        this.createRoad({
          latitude: event.latitude,
          longitude: event.longitude,
        });
      roadSegmentId = road.roadSegmentId;
      road.updatedAt = event.detectedAt;
      const traversalKey = `${roadSegmentId}:${event.movementType}`;
      const sessions = this.traversals.get(traversalKey) ?? new Set<string>();
      sessions.add(session.sessionId);
      this.traversals.set(traversalKey, sessions);
    }

    this.events.push({
      anonymousUserId: session.anonymousUserId,
      detectedAt: event.detectedAt,
      event: structuredClone(event),
      roadSegmentId,
      status,
    });

    return { eventId, roadSegmentId };
  }

  async nearbyRoads(query: NearbyRoadsQuery): Promise<RoadMapItem[]> {
    return [...this.roads.values()]
      .filter((road) => distanceMeters(road, query) <= query.radius)
      .map((road) => this.toRoadMapItem(road, query.movementType))
      .sort((first, second) => {
        if (first.score === null) return 1;
        if (second.score === null) return -1;
        return first.score - second.score;
      });
  }

  async getRoadDetail(
    roadSegmentId: string,
  ): Promise<RoadDetailResponse | null> {
    const road = this.roads.get(roadSegmentId);
    if (!road) return null;
    const events = this.acceptedEvents(roadSegmentId);
    const scores = movementTypes.map((movementType) =>
      this.toMovementScore(roadSegmentId, movementType),
    );

    return {
      eventCount: events.length,
      lastDetectedAt:
        events
          .map((event) => event.detectedAt)
          .sort()
          .at(-1) ?? null,
      latitude: road.latitude,
      longitude: road.longitude,
      recentEvents: events
        .sort((first, second) =>
          second.detectedAt.localeCompare(first.detectedAt),
        )
        .slice(0, 20)
        .map(({ event }) => ({
          detectedAt: event.detectedAt,
          gpsAccuracy: event.gpsAccuracy,
          impactLevel: event.impactLevel,
          severity: event.severity,
        })),
      roadName: road.roadName,
      roadSegmentId,
      scores,
      updatedAt: road.updatedAt,
    };
  }

  async getOverview(
    movementType?: MovementType,
  ): Promise<DashboardOverviewResponse> {
    const scopedRoads = [...this.roads.values()].filter(isWithinYongbongBounds);
    const scopedRoadIds = new Set(
      scopedRoads.map((road) => road.roadSegmentId),
    );
    const roadScores = scopedRoads.flatMap((road) =>
      (movementType ? [movementType] : movementTypes).map((type) =>
        this.toRoadMapItem(road, type),
      ),
    );
    const known = roadScores.filter((road) => road.score !== null);
    const accessibilityIndex =
      known.length === 0
        ? null
        : Number(
            (
              known.reduce((sum, road) => sum + (road.score ?? 0), 0) /
              known.length
            ).toFixed(1),
          );
    const accepted = this.events.filter(
      (event) =>
        event.status === "ACCEPTED" &&
        event.roadSegmentId !== null &&
        scopedRoadIds.has(event.roadSegmentId) &&
        (!movementType || event.event.movementType === movementType),
    );
    const knownRoadIds = new Set(known.map((road) => road.roadSegmentId));
    const highConfidenceRoadIds = new Set(
      known
        .filter((road) => road.confidenceLevel === "HIGH")
        .map((road) => road.roadSegmentId),
    );

    return {
      accessibilityIndex,
      acceptedEventCount: accepted.length,
      activeContributors: new Set(
        accepted.map((event) => event.anonymousUserId),
      ).size,
      analyzedDistanceMeters: knownRoadIds.size * 10,
      highConfidenceRoadCount: highConfidenceRoadIds.size,
      roadCount: knownRoadIds.size,
      unknownRoadCount: scopedRoads.length - knownRoadIds.size,
    };
  }

  async getPriorityRoads(
    limit: number,
    movementType?: MovementType,
  ): Promise<PriorityRoad[]> {
    return [...this.roads.values()]
      .filter(isWithinYongbongBounds)
      .flatMap((road) =>
        (movementType ? [movementType] : movementTypes).map((type) =>
          this.toRoadMapItem(road, type),
        ),
      )
      .filter(
        (road): road is RoadMapItem & { score: number } => road.score !== null,
      )
      .sort((first, second) => {
        const firstPriority = (100 - first.score) * (0.5 + first.confidence);
        const secondPriority = (100 - second.score) * (0.5 + second.confidence);
        return secondPriority - firstPriority;
      })
      .slice(0, limit)
      .map(
        ({
          confidence,
          confidenceLevel,
          eventCount,
          grade,
          movementType: type,
          roadName,
          roadSegmentId,
          score,
        }) => ({
          confidence,
          confidenceLevel,
          eventCount,
          grade,
          movementType: type,
          roadName,
          roadSegmentId,
          score,
        }),
      );
  }

  async ping(): Promise<boolean> {
    return true;
  }

  async upsertRoadSegments(roads: readonly RoadSegmentSeed[]): Promise<void> {
    const now = new Date().toISOString();
    for (const input of roads) {
      const existing = this.roads.get(input.roadSegmentId);
      this.roads.set(input.roadSegmentId, {
        latitude: input.latitude,
        longitude: input.longitude,
        roadName: input.roadName,
        roadSegmentId: input.roadSegmentId,
        updatedAt: existing?.updatedAt ?? now,
      });
    }
  }

  private createRoad(location: {
    latitude: number;
    longitude: number;
  }): MemoryRoad {
    const roadSegmentId = randomUUID();
    const now = new Date().toISOString();
    const road: MemoryRoad = {
      latitude: location.latitude,
      longitude: location.longitude,
      roadName: `Road DNA 구간 ${this.roads.size + 1}`,
      roadSegmentId,
      updatedAt: now,
    };
    this.roads.set(roadSegmentId, road);
    return road;
  }

  private acceptedEvents(
    roadSegmentId: string,
    movementType?: MovementType,
  ): MemoryEvent[] {
    return this.events.filter(
      (event) =>
        event.roadSegmentId === roadSegmentId &&
        event.status === "ACCEPTED" &&
        (!movementType || event.event.movementType === movementType),
    );
  }

  private aggregate(
    roadSegmentId: string,
    movementType: MovementType,
  ): RoadAggregate | null {
    const events = this.acceptedEvents(roadSegmentId, movementType);
    if (events.length === 0) return null;
    const traversalCount =
      this.traversals.get(`${roadSegmentId}:${movementType}`)?.size ?? 0;
    return {
      averageRms:
        events.reduce((sum, event) => sum + (event.event.window?.rms ?? 0), 0) /
        events.length,
      averageSeverity:
        events.reduce((sum, event) => sum + event.event.severity, 0) /
        events.length,
      eventCount: events.length,
      lastDetectedAt: events
        .map((event) => event.detectedAt)
        .sort()
        .at(-1)!,
      traversalCount,
      uniqueContributorCount: new Set(
        events.map((event) => event.anonymousUserId),
      ).size,
    };
  }

  private score(
    roadSegmentId: string,
    movementType: MovementType,
  ): RoadScoreResult {
    return calculateRoadScore(this.aggregate(roadSegmentId, movementType));
  }

  private toMovementScore(
    roadSegmentId: string,
    movementType: MovementType,
  ): MovementScore {
    const events = this.acceptedEvents(roadSegmentId, movementType);
    const score = this.score(roadSegmentId, movementType);
    return {
      ...score,
      eventCount: events.length,
      movementType,
    };
  }

  private toRoadMapItem(
    road: MemoryRoad,
    movementType: MovementType,
  ): RoadMapItem {
    const events = this.acceptedEvents(road.roadSegmentId, movementType);
    const score = this.score(road.roadSegmentId, movementType);
    return {
      ...score,
      eventCount: events.length,
      latitude: road.latitude,
      longitude: road.longitude,
      movementType,
      roadName: road.roadName,
      roadSegmentId: road.roadSegmentId,
      updatedAt: road.updatedAt,
    };
  }
}
