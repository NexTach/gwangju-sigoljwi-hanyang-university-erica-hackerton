import { randomUUID } from "node:crypto";
import type {
  CreateSensorEventRequest,
  CreateSessionRequest,
  DashboardOverviewResponse,
  EventStatus,
  ImpactLevel,
  MovementScore,
  MovementType,
  NearbyRoadsQuery,
  PriorityRoad,
  RoadDetailResponse,
  RoadMapItem,
} from "@road-dna/contracts";
import mysql, {
  type Pool,
  type PoolConnection,
  type ResultSetHeader,
  type RowDataPacket,
} from "mysql2/promise";
import type { AppConfig } from "../config.js";
import { calculateRoadScore, type RoadAggregate } from "../domain/scoring.js";
import {
  matchYongbongRoadHint,
  yongbongBounds,
} from "../support/yongbong-scenario.js";
import type {
  RecordEventResult,
  RoadRepository,
  RoadSegmentSeed,
  StoredSession,
} from "./repository.js";

type MysqlConfig = NonNullable<AppConfig["mysql"]>;

interface SessionRow extends RowDataPacket {
  anonymous_user_id: string;
  ended_at: string | null;
  movement_type: MovementType;
  session_id: string;
  started_at: string;
  status: StoredSession["status"];
}

interface RoadRow extends RowDataPacket {
  latitude: number;
  longitude: number;
  road_name: string;
  road_segment_id: string;
  updated_at: string;
}

interface RoadScoreRow extends RoadRow {
  confidence: number;
  confidence_level: RoadMapItem["confidenceLevel"];
  event_count: number;
  grade: RoadMapItem["grade"];
  movement_type: MovementType;
  score: number;
}

const movementTypes: MovementType[] = ["WHEELCHAIR", "STROLLER", "WALKING"];

const toIso = (value: string | Date): string => {
  if (value instanceof Date) return value.toISOString();
  const normalized = value.includes("T")
    ? value
    : `${value.replace(" ", "T")}Z`;
  return new Date(normalized).toISOString();
};

const sessionFromRow = (row: SessionRow): StoredSession => ({
  anonymousUserId: row.anonymous_user_id,
  endedAt: row.ended_at ? toIso(row.ended_at) : null,
  movementType: row.movement_type,
  sessionId: row.session_id,
  startedAt: toIso(row.started_at),
  status: row.status,
});

export function createMysqlPool(config: MysqlConfig): Pool {
  return mysql.createPool({
    charset: "utf8mb4",
    connectionLimit: config.connectionLimit,
    database: config.database,
    dateStrings: true,
    decimalNumbers: true,
    enableKeepAlive: true,
    gracefulEnd: true,
    host: config.host,
    namedPlaceholders: true,
    password: config.password,
    port: config.port,
    timezone: "Z",
    user: config.user,
  });
}

export class MysqlRoadRepository implements RoadRepository {
  constructor(private readonly pool: Pool) {}

  async close(): Promise<void> {
    await this.pool.end();
  }

  async createSession(input: CreateSessionRequest): Promise<StoredSession> {
    const sessionId = randomUUID();
    const connection = await this.pool.getConnection();
    try {
      await connection.beginTransaction();
      await connection.execute(
        `INSERT IGNORE INTO anonymous_users (user_id)
         VALUES (:userId)`,
        { userId: input.anonymousUserId },
      );
      await connection.execute(
        `INSERT INTO movement_sessions (
          session_id, anonymous_user_id, movement_type, status, started_at,
          app_version, device_model
        ) VALUES (
          :sessionId, :anonymousUserId, :movementType, 'ACTIVE', :startedAt,
          :appVersion, :deviceModel
        )`,
        {
          anonymousUserId: input.anonymousUserId,
          appVersion: input.appVersion ?? null,
          deviceModel: input.deviceModel ?? null,
          movementType: input.movementType,
          sessionId,
          startedAt: new Date(input.startedAt),
        },
      );
      await connection.commit();
      return {
        anonymousUserId: input.anonymousUserId,
        endedAt: null,
        movementType: input.movementType,
        sessionId,
        startedAt: input.startedAt,
        status: "ACTIVE",
      };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async endSession(
    sessionId: string,
    endedAt: string,
  ): Promise<StoredSession | null> {
    const [result] = await this.pool.execute<ResultSetHeader>(
      `UPDATE movement_sessions
       SET status = 'COMPLETED', ended_at = :endedAt
       WHERE session_id = :sessionId AND status = 'ACTIVE'`,
      { endedAt: new Date(endedAt), sessionId },
    );
    if (result.affectedRows === 0) return null;
    return this.getSession(sessionId);
  }

  async getSession(sessionId: string): Promise<StoredSession | null> {
    const [rows] = await this.pool.execute<SessionRow[]>(
      `SELECT session_id, anonymous_user_id, movement_type, status,
              started_at, ended_at
       FROM movement_sessions
       WHERE session_id = :sessionId
       LIMIT 1`,
      { sessionId },
    );
    return rows[0] ? sessionFromRow(rows[0]) : null;
  }

  async recordEvent(
    session: StoredSession,
    event: CreateSensorEventRequest,
    status: EventStatus,
  ): Promise<RecordEventResult> {
    const connection = await this.pool.getConnection();
    const eventId = randomUUID();
    try {
      await connection.beginTransaction();
      let roadSegmentId: string | null = null;

      if (status === "ACCEPTED") {
        roadSegmentId = await this.findOrCreateRoad(connection, event);
      }

      await connection.execute(
        `INSERT INTO sensor_events (
          event_id, session_id, road_segment_id, movement_type, event_status,
          impact_level, latitude, longitude, gps_accuracy, speed, severity,
          anomaly_score, peak_value, window_duration_ms, window_mean,
          window_std, window_rms, window_peak_count, detected_at
        ) VALUES (
          :eventId, :sessionId, :roadSegmentId, :movementType, :eventStatus,
          :impactLevel, :latitude, :longitude, :gpsAccuracy, :speed, :severity,
          :anomalyScore, :peakValue, :windowDurationMs, :windowMean,
          :windowStd, :windowRms, :windowPeakCount, :detectedAt
        )`,
        {
          anomalyScore: event.anomalyScore,
          detectedAt: new Date(event.detectedAt),
          eventId,
          eventStatus: status,
          gpsAccuracy: event.gpsAccuracy,
          impactLevel: event.impactLevel,
          latitude: event.latitude,
          longitude: event.longitude,
          movementType: event.movementType,
          peakValue: event.peakValue,
          roadSegmentId,
          sessionId: session.sessionId,
          severity: event.severity,
          speed: event.speed ?? null,
          windowDurationMs: event.window?.durationMs ?? null,
          windowMean: event.window?.mean ?? null,
          windowPeakCount: event.window?.peakCount ?? null,
          windowRms: event.window?.rms ?? null,
          windowStd: event.window?.standardDeviation ?? null,
        },
      );

      if (roadSegmentId) {
        await connection.execute(
          `INSERT IGNORE INTO road_traversals (
            road_segment_id, session_id, movement_type, first_detected_at
          ) VALUES (
            :roadSegmentId, :sessionId, :movementType, :detectedAt
          )`,
          {
            detectedAt: new Date(event.detectedAt),
            movementType: event.movementType,
            roadSegmentId,
            sessionId: session.sessionId,
          },
        );
        await this.updateScore(connection, roadSegmentId, event.movementType);
        await connection.execute(
          `UPDATE road_segments SET updated_at = :detectedAt
           WHERE road_segment_id = :roadSegmentId`,
          {
            detectedAt: new Date(event.detectedAt),
            roadSegmentId,
          },
        );
      }

      await connection.commit();
      return { eventId, roadSegmentId };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  async nearbyRoads(query: NearbyRoadsQuery): Promise<RoadMapItem[]> {
    const [rows] = await this.pool.execute<RoadScoreRow[]>(
      `SELECT
        rs.road_segment_id,
        rs.road_name,
        ST_Latitude(rs.location) AS latitude,
        ST_Longitude(rs.location) AS longitude,
        rs.updated_at,
        score.movement_type,
        score.score,
        score.grade,
        score.confidence,
        score.confidence_level,
        score.event_count
       FROM road_segments rs
       INNER JOIN road_scores score
         ON score.road_segment_id = rs.road_segment_id
        AND score.movement_type = :movementType
       WHERE ST_Distance_Sphere(
         rs.location,
         ST_SRID(POINT(:longitude, :latitude), 4326)
       ) <= :radius
       ORDER BY score.score ASC, score.confidence DESC
       LIMIT 200`,
      query,
    );
    return rows.map((row) => this.mapRoadScore(row));
  }

  async getRoadDetail(
    roadSegmentId: string,
  ): Promise<RoadDetailResponse | null> {
    const [roadRows] = await this.pool.execute<RoadRow[]>(
      `SELECT road_segment_id, road_name,
              ST_Latitude(location) AS latitude,
              ST_Longitude(location) AS longitude,
              updated_at
       FROM road_segments
       WHERE road_segment_id = :roadSegmentId
       LIMIT 1`,
      { roadSegmentId },
    );
    const road = roadRows[0];
    if (!road) return null;

    const [scoreRows] = await this.pool.execute<RoadScoreRow[]>(
      `SELECT :roadSegmentId AS road_segment_id, '' AS road_name,
              0 AS latitude, 0 AS longitude, updated_at,
              movement_type, score, grade, confidence, confidence_level,
              event_count
       FROM road_scores
       WHERE road_segment_id = :roadSegmentId`,
      { roadSegmentId },
    );
    const [eventRows] = await this.pool.execute<
      Array<
        RowDataPacket & {
          detected_at: string;
          gps_accuracy: number;
          impact_level: ImpactLevel;
          severity: number;
        }
      >
    >(
      `SELECT detected_at, gps_accuracy, impact_level, severity
       FROM sensor_events
       WHERE road_segment_id = :roadSegmentId AND event_status = 'ACCEPTED'
       ORDER BY detected_at DESC
       LIMIT 20`,
      { roadSegmentId },
    );
    const scoreByMovement = new Map(
      scoreRows.map((score) => [score.movement_type, score]),
    );
    const scores: MovementScore[] = movementTypes.map((movementType) => {
      const score = scoreByMovement.get(movementType);
      return score
        ? {
            confidence: score.confidence,
            confidenceLevel: score.confidence_level,
            eventCount: score.event_count,
            grade: score.grade,
            movementType,
            score: score.score,
          }
        : {
            confidence: 0,
            confidenceLevel: "LOW",
            eventCount: 0,
            grade: "UNKNOWN",
            movementType,
            score: null,
          };
    });

    return {
      eventCount: scoreRows.reduce((sum, score) => sum + score.event_count, 0),
      lastDetectedAt: eventRows[0] ? toIso(eventRows[0].detected_at) : null,
      latitude: road.latitude,
      longitude: road.longitude,
      recentEvents: eventRows.map((event) => ({
        detectedAt: toIso(event.detected_at),
        gpsAccuracy: event.gps_accuracy,
        impactLevel: event.impact_level,
        severity: event.severity,
      })),
      roadName: road.road_name,
      roadSegmentId,
      scores,
      updatedAt: toIso(road.updated_at),
    };
  }

  async getOverview(
    movementType?: MovementType,
  ): Promise<DashboardOverviewResponse> {
    const [scoreRows] = await this.pool.execute<
      Array<
        RowDataPacket & {
          accessibility_index: number | null;
          high_confidence_count: number | null;
          road_count: number;
          total_road_count: number;
        }
      >
    >(
      `SELECT
         ROUND(AVG(scores.score), 1) AS accessibility_index,
         COUNT(DISTINCT CASE
           WHEN scores.score IS NOT NULL THEN roads.road_segment_id
         END) AS road_count,
         COUNT(DISTINCT roads.road_segment_id) AS total_road_count,
         COUNT(DISTINCT CASE
           WHEN scores.confidence_level = 'HIGH' THEN roads.road_segment_id
         END) AS high_confidence_count
       FROM road_segments roads
       LEFT JOIN road_scores scores
         ON scores.road_segment_id = roads.road_segment_id
        AND (:movementType IS NULL OR scores.movement_type = :movementType)
       WHERE ST_Latitude(roads.location)
               BETWEEN :minimumLatitude AND :maximumLatitude
         AND ST_Longitude(roads.location)
               BETWEEN :minimumLongitude AND :maximumLongitude`,
      {
        ...yongbongBounds,
        movementType: movementType ?? null,
      },
    );
    const [eventRows] = await this.pool.execute<
      Array<
        RowDataPacket & {
          accepted_event_count: number;
          active_contributors: number;
        }
      >
    >(
      `SELECT
         COUNT(*) AS accepted_event_count,
         COUNT(DISTINCT sessions.anonymous_user_id) AS active_contributors
       FROM sensor_events events
       INNER JOIN movement_sessions sessions
         ON sessions.session_id = events.session_id
       INNER JOIN road_segments roads
         ON roads.road_segment_id = events.road_segment_id
       WHERE events.event_status = 'ACCEPTED'
         AND (:movementType IS NULL OR events.movement_type = :movementType)
         AND ST_Latitude(roads.location)
               BETWEEN :minimumLatitude AND :maximumLatitude
         AND ST_Longitude(roads.location)
               BETWEEN :minimumLongitude AND :maximumLongitude`,
      {
        ...yongbongBounds,
        movementType: movementType ?? null,
      },
    );
    const score = scoreRows[0]!;
    const events = eventRows[0]!;
    return {
      accessibilityIndex: score.accessibility_index,
      acceptedEventCount: events.accepted_event_count,
      activeContributors: events.active_contributors,
      analyzedDistanceMeters: score.road_count * 10,
      highConfidenceRoadCount: score.high_confidence_count ?? 0,
      roadCount: score.road_count,
      unknownRoadCount: score.total_road_count - score.road_count,
    };
  }

  async getPriorityRoads(
    limit: number,
    movementType?: MovementType,
  ): Promise<PriorityRoad[]> {
    const [rows] = await this.pool.query<RoadScoreRow[]>(
      `SELECT
         roads.road_segment_id,
         roads.road_name,
         ST_Latitude(roads.location) AS latitude,
         ST_Longitude(roads.location) AS longitude,
         roads.updated_at,
         scores.movement_type,
         scores.score,
         scores.grade,
         scores.confidence,
         scores.confidence_level,
         scores.event_count
       FROM road_scores scores
       INNER JOIN road_segments roads
         ON roads.road_segment_id = scores.road_segment_id
       WHERE (:movementType IS NULL OR scores.movement_type = :movementType)
         AND ST_Latitude(roads.location)
               BETWEEN :minimumLatitude AND :maximumLatitude
         AND ST_Longitude(roads.location)
               BETWEEN :minimumLongitude AND :maximumLongitude
       ORDER BY
         (100 - scores.score) * (0.5 + scores.confidence) DESC,
         scores.event_count DESC
       LIMIT :limit`,
      {
        ...yongbongBounds,
        limit,
        movementType: movementType ?? null,
      },
    );
    return rows.map((row) => ({
      confidence: row.confidence,
      confidenceLevel: row.confidence_level,
      eventCount: row.event_count,
      grade: row.grade,
      movementType: row.movement_type,
      roadName: row.road_name,
      roadSegmentId: row.road_segment_id,
      score: row.score,
    }));
  }

  async ping(): Promise<boolean> {
    try {
      await this.pool.query("SELECT 1");
      return true;
    } catch {
      return false;
    }
  }

  async upsertRoadSegments(roads: readonly RoadSegmentSeed[]): Promise<void> {
    if (roads.length === 0) return;
    const connection = await this.pool.getConnection();
    try {
      await connection.beginTransaction();
      for (const road of roads) {
        await this.upsertRoadSegment(connection, road);
      }
      await connection.commit();
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  private async findOrCreateRoad(
    connection: PoolConnection,
    event: CreateSensorEventRequest,
  ): Promise<string> {
    const hintedRoad = matchYongbongRoadHint(event);
    if (hintedRoad) {
      await this.upsertRoadSegment(connection, hintedRoad);
      return hintedRoad.roadSegmentId;
    }

    const [rows] = await connection.execute<
      Array<RowDataPacket & { road_segment_id: string }>
    >(
      `SELECT road_segment_id
       FROM road_segments
       WHERE ST_Distance_Sphere(
         location,
         ST_SRID(POINT(:longitude, :latitude), 4326)
       ) <= 10
       ORDER BY ST_Distance_Sphere(
         location,
         ST_SRID(POINT(:longitude, :latitude), 4326)
       ) ASC
       LIMIT 1
       FOR UPDATE`,
      {
        latitude: event.latitude,
        longitude: event.longitude,
      },
    );
    if (rows[0]) return rows[0].road_segment_id;

    const roadSegmentId = randomUUID();
    await connection.execute(
      `INSERT INTO road_segments (
        road_segment_id, road_name, location, updated_at
       ) VALUES (
        :roadSegmentId,
        :roadName,
        ST_SRID(POINT(:longitude, :latitude), 4326),
        :updatedAt
       )`,
      {
        latitude: event.latitude,
        longitude: event.longitude,
        roadName: `Road DNA 구간 ${event.latitude.toFixed(4)}, ${event.longitude.toFixed(4)}`,
        roadSegmentId,
        updatedAt: new Date(event.detectedAt),
      },
    );
    return roadSegmentId;
  }

  private async upsertRoadSegment(
    connection: PoolConnection,
    road: RoadSegmentSeed,
  ): Promise<void> {
    await connection.execute(
      `INSERT INTO road_segments (
         road_segment_id, road_name, location
       ) VALUES (
         :roadSegmentId,
         :roadName,
         ST_SRID(POINT(:longitude, :latitude), 4326)
       )
       ON DUPLICATE KEY UPDATE
         road_name = :roadName,
         location = ST_SRID(POINT(:longitude, :latitude), 4326)`,
      {
        latitude: road.latitude,
        longitude: road.longitude,
        roadName: road.roadName,
        roadSegmentId: road.roadSegmentId,
      },
    );
  }

  private async updateScore(
    connection: PoolConnection,
    roadSegmentId: string,
    movementType: MovementType,
  ): Promise<void> {
    const [aggregateRows] = await connection.execute<
      Array<
        RowDataPacket & {
          average_rms: number | null;
          average_severity: number;
          event_count: number;
          last_detected_at: string;
          traversal_count: number;
          unique_contributor_count: number;
        }
      >
    >(
      `SELECT
         COUNT(*) AS event_count,
         AVG(events.severity) AS average_severity,
         COALESCE(AVG(events.window_rms), 0) AS average_rms,
         COUNT(DISTINCT sessions.anonymous_user_id)
           AS unique_contributor_count,
         (
           SELECT COUNT(*)
           FROM road_traversals traversals
           WHERE traversals.road_segment_id = :roadSegmentId
             AND traversals.movement_type = :movementType
         ) AS traversal_count,
         MAX(events.detected_at) AS last_detected_at
       FROM sensor_events events
       INNER JOIN movement_sessions sessions
         ON sessions.session_id = events.session_id
       WHERE events.road_segment_id = :roadSegmentId
         AND events.movement_type = :movementType
         AND events.event_status = 'ACCEPTED'`,
      { movementType, roadSegmentId },
    );
    const row = aggregateRows[0]!;
    const aggregate: RoadAggregate = {
      averageRms: row.average_rms ?? 0,
      averageSeverity: row.average_severity,
      eventCount: row.event_count,
      lastDetectedAt: toIso(row.last_detected_at),
      traversalCount: row.traversal_count,
      uniqueContributorCount: row.unique_contributor_count,
    };
    const result = calculateRoadScore(aggregate);
    if (result.score === null || result.grade === "UNKNOWN") return;

    await connection.execute(
      `INSERT INTO road_scores (
        score_id, road_segment_id, movement_type, score, grade, confidence,
        confidence_level, event_count, unique_contributor_count,
        traversal_count, updated_at
       ) VALUES (
        :scoreId, :roadSegmentId, :movementType, :score, :grade, :confidence,
        :confidenceLevel, :eventCount, :uniqueContributorCount,
        :traversalCount, CURRENT_TIMESTAMP(3)
       )
       ON DUPLICATE KEY UPDATE
        score = VALUES(score),
        grade = VALUES(grade),
        confidence = VALUES(confidence),
        confidence_level = VALUES(confidence_level),
        event_count = VALUES(event_count),
        unique_contributor_count = VALUES(unique_contributor_count),
        traversal_count = VALUES(traversal_count),
        updated_at = CURRENT_TIMESTAMP(3)`,
      {
        confidence: result.confidence,
        confidenceLevel: result.confidenceLevel,
        eventCount: aggregate.eventCount,
        grade: result.grade,
        movementType,
        roadSegmentId,
        score: result.score,
        scoreId: randomUUID(),
        traversalCount: aggregate.traversalCount,
        uniqueContributorCount: aggregate.uniqueContributorCount,
      },
    );
  }

  private mapRoadScore(row: RoadScoreRow): RoadMapItem {
    return {
      confidence: row.confidence,
      confidenceLevel: row.confidence_level,
      eventCount: row.event_count,
      grade: row.grade,
      latitude: row.latitude,
      longitude: row.longitude,
      movementType: row.movement_type,
      roadName: row.road_name,
      roadSegmentId: row.road_segment_id,
      score: row.score,
      updatedAt: toIso(row.updated_at),
    };
  }
}
