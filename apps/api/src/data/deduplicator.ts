import type { CreateSensorEventRequest } from "@road-dna/contracts";
import { Redis } from "ioredis";
import type { EventDeduplicator } from "./repository.js";

const eventKey = (
  sessionId: string,
  event: CreateSensorEventRequest,
): string => {
  const latitude = event.latitude.toFixed(5);
  const longitude = event.longitude.toFixed(5);
  const bucket = Math.floor(new Date(event.detectedAt).getTime() / 5_000);
  return `road-dna:event:${sessionId}:${latitude}:${longitude}:${bucket}`;
};

export class MemoryEventDeduplicator implements EventDeduplicator {
  private readonly expirations = new Map<string, number>();

  async close(): Promise<void> {}

  async isDuplicate(
    sessionId: string,
    event: CreateSensorEventRequest,
  ): Promise<boolean> {
    const now = Date.now();
    for (const [key, expiration] of this.expirations) {
      if (expiration <= now) this.expirations.delete(key);
    }
    const key = eventKey(sessionId, event);
    if (this.expirations.has(key)) return true;
    this.expirations.set(key, now + 5_000);
    return false;
  }

  async ping(): Promise<boolean> {
    return true;
  }
}

export class RedisEventDeduplicator implements EventDeduplicator {
  private readonly redis: Redis;

  constructor(url: string) {
    this.redis = new Redis(url, {
      enableOfflineQueue: false,
      lazyConnect: true,
      maxRetriesPerRequest: 1,
      retryStrategy: (attempt) => (attempt <= 3 ? attempt * 200 : undefined),
    });
    this.redis.on("error", () => {
      // Fastify health output reports availability without logging secrets.
    });
  }

  async close(): Promise<void> {
    await this.redis.quit().catch(() => this.redis.disconnect());
  }

  async isDuplicate(
    sessionId: string,
    event: CreateSensorEventRequest,
  ): Promise<boolean> {
    try {
      if (this.redis.status === "wait") await this.redis.connect();
      const result = await this.redis.set(
        eventKey(sessionId, event),
        "1",
        "EX",
        5,
        "NX",
      );
      return result !== "OK";
    } catch {
      return false;
    }
  }

  async ping(): Promise<boolean> {
    try {
      if (this.redis.status === "wait") await this.redis.connect();
      return (await this.redis.ping()) === "PONG";
    } catch {
      return false;
    }
  }
}
