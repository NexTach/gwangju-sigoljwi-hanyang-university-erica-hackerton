import { describe, expect, it } from "vitest";
import {
  cleanupExpiredData,
  type RetentionExecute,
} from "./retention-cleanup.js";

describe("Describe 보관기간 정리", () => {
  describe("Context 앱 강제 종료로 오래된 ACTIVE 세션이 남은 경우", () => {
    it("It 명확한 시작 시각 조건으로 먼저 CANCELLED 처리한다", async () => {
      const statements: string[] = [];
      const cutoffs: Date[] = [];
      const affectedRows = [2, 3, 4, 5, 6];
      const cutoff = new Date("2026-04-20T00:00:00.000Z");
      const execute: RetentionExecute = async (statement, values) => {
        statements.push(statement.replace(/\s+/g, " ").trim());
        cutoffs.push(values.cutoff);
        return { affectedRows: affectedRows.shift() ?? 0 };
      };

      const result = await cleanupExpiredData(execute, cutoff);

      expect(statements[0]).toContain("UPDATE movement_sessions");
      expect(statements[0]).toContain("SET status = 'CANCELLED'");
      expect(statements[0]).toContain(
        "ended_at = COALESCE(ended_at, started_at)",
      );
      expect(statements[0]).toContain(
        "WHERE status = 'ACTIVE' AND started_at < :cutoff",
      );
      expect(statements[1]).toContain("DELETE FROM road_traversals");
      expect(statements[2]).toContain("DELETE FROM sensor_events");
      expect(statements[3]).toContain("DELETE session");
      expect(statements[4]).toContain("DELETE anonymous");
      expect(cutoffs).toEqual(Array.from({ length: 5 }, () => cutoff));
      expect(result).toEqual({
        anonymousUsers: 6,
        cancelledStaleSessions: 2,
        events: 4,
        sessions: 5,
        traversals: 3,
      });
    });
  });
});
