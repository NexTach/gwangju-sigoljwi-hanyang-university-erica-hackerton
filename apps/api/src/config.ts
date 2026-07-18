export interface AppConfig {
  corsOrigins: string[];
  demoMode: boolean;
  host: string;
  logLevel: string;
  mysql: {
    connectionLimit: number;
    database: string;
    host: string;
    password: string;
    port: number;
    user: string;
  } | null;
  port: number;
  publicPathPrefix: string;
  redisUrl: string | null;
}

const integer = (value: string | undefined, fallback: number): number => {
  if (value === undefined) return fallback;
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed)) {
    throw new Error(
      `Expected an integer environment value, received "${value}"`,
    );
  }
  return parsed;
};

const boolean = (value: string | undefined, fallback: boolean): boolean => {
  if (value === undefined) return fallback;
  return ["1", "true", "yes", "on"].includes(value.toLowerCase());
};

const pathPrefix = (value: string | undefined): string => {
  const prefix = value?.trim() ?? "";
  if (!prefix) return "";
  if (
    !prefix.startsWith("/") ||
    prefix.endsWith("/") ||
    !/^\/[a-zA-Z0-9/_-]+$/.test(prefix)
  ) {
    throw new Error(
      'PUBLIC_PATH_PREFIX must be empty or a safe path such as "/road-dna".',
    );
  }
  return prefix;
};

export function loadConfig(environment = process.env): AppConfig {
  const mysqlHost = environment.MYSQL_HOST?.trim();
  const mysql = mysqlHost
    ? {
        connectionLimit: integer(environment.MYSQL_CONNECTION_LIMIT, 10),
        database: environment.MYSQL_DATABASE?.trim() || "road_dna",
        host: mysqlHost,
        password: environment.MYSQL_PASSWORD ?? "",
        port: integer(environment.MYSQL_PORT, 3306),
        user: environment.MYSQL_USER?.trim() || "root",
      }
    : null;

  if (mysql && mysql.database !== "road_dna") {
    throw new Error(
      'MYSQL_DATABASE must remain "road_dna" to protect unrelated schemas.',
    );
  }

  return {
    corsOrigins: (environment.CORS_ORIGINS ?? "http://localhost:5173")
      .split(",")
      .map((origin) => origin.trim())
      .filter(Boolean),
    demoMode: boolean(environment.DEMO_MODE, false),
    host: environment.HOST?.trim() || "0.0.0.0",
    logLevel: environment.LOG_LEVEL?.trim() || "info",
    mysql,
    port: integer(environment.PORT, 3000),
    publicPathPrefix: pathPrefix(environment.PUBLIC_PATH_PREFIX),
    redisUrl: environment.REDIS_URL?.trim() || null,
  };
}
