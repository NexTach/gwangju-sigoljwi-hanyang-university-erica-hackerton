export interface RetentionCleanupResult {
  anonymousUsers: number;
  cancelledStaleSessions: number;
  events: number;
  sessions: number;
  traversals: number;
}

export type RetentionExecute = (
  statement: string,
  values: { cutoff: Date },
) => Promise<{ affectedRows: number }>;

export async function cleanupExpiredData(
  execute: RetentionExecute,
  cutoff: Date,
): Promise<RetentionCleanupResult> {
  const cancelled = await execute(
    `UPDATE movement_sessions
     SET status = 'CANCELLED',
         ended_at = COALESCE(ended_at, started_at)
     WHERE status = 'ACTIVE'
       AND started_at < :cutoff`,
    { cutoff },
  );
  const traversals = await execute(
    `DELETE FROM road_traversals
     WHERE first_detected_at < :cutoff`,
    { cutoff },
  );
  const events = await execute(
    `DELETE FROM sensor_events
     WHERE detected_at < :cutoff`,
    { cutoff },
  );
  const sessions = await execute(
    `DELETE session
     FROM movement_sessions session
     LEFT JOIN sensor_events event
       ON event.session_id = session.session_id
     LEFT JOIN road_traversals traversal
       ON traversal.session_id = session.session_id
     WHERE session.status <> 'ACTIVE'
       AND session.ended_at < :cutoff
       AND event.event_id IS NULL
       AND traversal.session_id IS NULL`,
    { cutoff },
  );
  const users = await execute(
    `DELETE anonymous
     FROM anonymous_users anonymous
     LEFT JOIN movement_sessions session
       ON session.anonymous_user_id = anonymous.user_id
     WHERE session.session_id IS NULL
       AND anonymous.created_at < :cutoff`,
    { cutoff },
  );

  return {
    anonymousUsers: users.affectedRows,
    cancelledStaleSessions: cancelled.affectedRows,
    events: events.affectedRows,
    sessions: sessions.affectedRows,
    traversals: traversals.affectedRows,
  };
}
