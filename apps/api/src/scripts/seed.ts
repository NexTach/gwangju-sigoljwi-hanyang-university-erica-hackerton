import type { RowDataPacket } from "mysql2";
import { loadConfig } from "../config.js";
import {
  createMysqlPool,
  MysqlRoadRepository,
} from "../data/mysql-repository.js";
import { seedDemoData } from "../support/demo-data.js";

const config = loadConfig();
if (!config.mysql) {
  throw new Error("MYSQL_HOST is required to seed the database.");
}

const pool = createMysqlPool(config.mysql);
const [rows] = await pool.query<Array<RowDataPacket & { event_count: number }>>(
  "SELECT COUNT(*) AS event_count FROM sensor_events",
);
if (
  Number(rows[0]?.event_count ?? 0) > 0 &&
  !process.argv.includes("--force")
) {
  console.log("Seed skipped: sensor_events already contains data.");
  await pool.end();
} else {
  const repository = new MysqlRoadRepository(pool);
  const result = await seedDemoData(repository);
  await repository.close();
  console.log(
    `Seeded ${result.sessionCount} sessions and ${result.eventCount} events.`,
  );
}
