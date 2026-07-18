import { readdir, readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import mysql from "mysql2/promise";
import { loadConfig } from "../config.js";
import { createMysqlPool } from "../data/mysql-repository.js";

const config = loadConfig();
if (!config.mysql) {
  throw new Error("MYSQL_HOST is required to run database migrations.");
}

// The plan has one isolated schema. Never interpolate an arbitrary schema name.
if (config.mysql.database !== "road_dna") {
  throw new Error("Only the dedicated road_dna schema may be migrated.");
}

const admin = await mysql.createConnection({
  charset: "utf8mb4",
  host: config.mysql.host,
  password: config.mysql.password,
  port: config.mysql.port,
  user: config.mysql.user,
});
await admin.query(
  "CREATE DATABASE IF NOT EXISTS `road_dna` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci",
);
await admin.end();

const migrationsDirectory = fileURLToPath(
  new URL("../../migrations/", import.meta.url),
);
const migrationFiles = (await readdir(migrationsDirectory))
  .filter((name) => /^\d+_.+\.sql$/.test(name))
  .sort();
const pool = createMysqlPool(config.mysql);

try {
  for (const migrationFile of migrationFiles) {
    const [existing] = await pool.query<mysql.RowDataPacket[]>(
      `SELECT COUNT(*) AS table_count
       FROM information_schema.tables
       WHERE table_schema = 'road_dna'
         AND table_name = 'schema_migrations'`,
    );
    if (Number(existing[0]?.table_count ?? 0) > 0) {
      const [applied] = await pool.execute<mysql.RowDataPacket[]>(
        `SELECT migration_name
         FROM schema_migrations
         WHERE migration_name = :migrationFile`,
        { migrationFile },
      );
      if (applied.length > 0) continue;
    }

    const sql = await readFile(
      new URL(`../../migrations/${migrationFile}`, import.meta.url),
      "utf8",
    );
    const statements = sql
      .split(/;\s*(?:\n|$)/)
      .map((statement) => statement.trim())
      .filter(Boolean);
    for (const statement of statements) {
      await pool.query(statement);
    }
    await pool.execute(
      `INSERT IGNORE INTO schema_migrations (migration_name)
       VALUES (:migrationFile)`,
      { migrationFile },
    );
    console.log(`Applied ${migrationFile}`);
  }
} finally {
  await pool.end();
}
