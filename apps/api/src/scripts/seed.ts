import { loadConfig } from "../config.js";
import {
  createMysqlPool,
  MysqlRoadRepository,
} from "../data/mysql-repository.js";
import { seedYongbongScenario } from "../support/yongbong-scenario.js";

const config = loadConfig();
if (!config.mysql) {
  throw new Error("MYSQL_HOST is required to seed the database.");
}

const pool = createMysqlPool(config.mysql);
const repository = new MysqlRoadRepository(pool);
const result = await seedYongbongScenario(repository);
await repository.close();
if (result.eventCount === 0) {
  console.log("Yongbong scenario data is already synchronized.");
} else {
  console.log(
    `Synchronized ${result.sessionCount} Yongbong sessions and ${result.eventCount} events.`,
  );
}
