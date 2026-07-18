import type { ResultSetHeader } from "mysql2";
import { loadConfig } from "../config.js";
import { createMysqlPool } from "../data/mysql-repository.js";

const config = loadConfig();
if (!config.mysql) {
  throw new Error("MYSQL_HOST is required to run retention cleanup.");
}

const parsedDays = Number.parseInt(
  process.env.EVENT_RETENTION_DAYS ?? "90",
  10,
);
if (!Number.isInteger(parsedDays) || parsedDays < 30 || parsedDays > 3650) {
  throw new Error("EVENT_RETENTION_DAYS must be between 30 and 3650.");
}

const cutoff = new Date(Date.now() - parsedDays * 24 * 60 * 60 * 1000);
const pool = createMysqlPool(config.mysql);
const connection = await pool.getConnection();

try {
  await connection.beginTransaction();
  const [traversals] = await connection.execute<ResultSetHeader>(
    `DELETE FROM road_traversals
     WHERE first_detected_at < :cutoff`,
    { cutoff },
  );
  const [events] = await connection.execute<ResultSetHeader>(
    `DELETE FROM sensor_events
     WHERE detected_at < :cutoff`,
    { cutoff },
  );
  const [sessions] = await connection.execute<ResultSetHeader>(
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
  const [users] = await connection.execute<ResultSetHeader>(
    `DELETE anonymous
     FROM anonymous_users anonymous
     LEFT JOIN movement_sessions session
       ON session.anonymous_user_id = anonymous.user_id
     WHERE session.session_id IS NULL
       AND anonymous.created_at < :cutoff`,
    { cutoff },
  );
  await connection.commit();
  console.log(
    JSON.stringify({
      cutoff: cutoff.toISOString(),
      deleted: {
        anonymousUsers: users.affectedRows,
        events: events.affectedRows,
        sessions: sessions.affectedRows,
        traversals: traversals.affectedRows,
      },
      retentionDays: parsedDays,
    }),
  );
} catch (error) {
  await connection.rollback();
  throw error;
} finally {
  connection.release();
  await pool.end();
}
