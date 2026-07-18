import type { ResultSetHeader } from "mysql2";
import { loadConfig } from "../config.js";
import { createMysqlPool } from "../data/mysql-repository.js";
import { cleanupExpiredData } from "../support/retention-cleanup.js";

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
  const deleted = await cleanupExpiredData(async (statement, values) => {
    const [result] = await connection.execute<ResultSetHeader>(
      statement,
      values,
    );
    return result;
  }, cutoff);
  await connection.commit();
  console.log(
    JSON.stringify({
      cutoff: cutoff.toISOString(),
      deleted,
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
