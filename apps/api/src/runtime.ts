import type { AppConfig } from "./config.js";
import {
  MemoryEventDeduplicator,
  RedisEventDeduplicator,
} from "./data/deduplicator.js";
import { MemoryRoadRepository } from "./data/memory-repository.js";
import {
  createMysqlPool,
  MysqlRoadRepository,
} from "./data/mysql-repository.js";
import type { EventDeduplicator, RoadRepository } from "./data/repository.js";

export interface RuntimeDependencies {
  deduplicator: EventDeduplicator;
  repository: RoadRepository;
}

export function createRuntimeDependencies(
  config: AppConfig,
): RuntimeDependencies {
  const repository = config.mysql
    ? new MysqlRoadRepository(createMysqlPool(config.mysql))
    : new MemoryRoadRepository();
  const deduplicator = config.redisUrl
    ? new RedisEventDeduplicator(config.redisUrl)
    : new MemoryEventDeduplicator();

  return { deduplicator, repository };
}
