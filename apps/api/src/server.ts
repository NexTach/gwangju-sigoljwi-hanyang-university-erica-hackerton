import { buildApp } from "./app.js";
import { loadConfig } from "./config.js";
import { createRuntimeDependencies } from "./runtime.js";
import { seedDemoData } from "./support/demo-data.js";

const config = loadConfig();
const dependencies = createRuntimeDependencies(config);

if (config.demoMode && !config.mysql) {
  await seedDemoData(dependencies.repository);
}

const app = buildApp({
  corsOrigins: config.corsOrigins,
  deduplicator: dependencies.deduplicator,
  logger: { level: config.logLevel },
  publicPathPrefix: config.publicPathPrefix,
  repository: dependencies.repository,
});

await app.listen({ host: config.host, port: config.port });

let isClosing = false;
const close = async (signal: NodeJS.Signals): Promise<void> => {
  if (isClosing) return;
  isClosing = true;
  app.log.info({ signal }, "Shutting down Road DNA API");
  await app.close();
};

process.once("SIGINT", () => void close("SIGINT"));
process.once("SIGTERM", () => void close("SIGTERM"));
