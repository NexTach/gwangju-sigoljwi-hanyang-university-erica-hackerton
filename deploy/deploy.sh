#!/bin/sh
set -eu

PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:${PATH:-}"
export PATH

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ENV_FILE=${ROAD_DNA_ENV_FILE:-"$SCRIPT_DIR/.env"}
RELEASE_FILE=${ROAD_DNA_RELEASE_FILE:-"$SCRIPT_DIR/release.env"}
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.prod.yml"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing production environment file: $ENV_FILE" >&2
  exit 1
fi

if [ ! -f "$RELEASE_FILE" ]; then
  echo "Missing release image file: $RELEASE_FILE" >&2
  exit 1
fi

set -a
. "$ENV_FILE"
. "$RELEASE_FILE"
set +a
ROAD_DNA_ENV_FILE=$ENV_FILE
export ROAD_DNA_ENV_FILE

compose() {
  docker compose \
    --env-file "$ENV_FILE" \
    --env-file "$RELEASE_FILE" \
    -f "$COMPOSE_FILE" \
    "$@"
}

compose pull
compose run --rm --no-deps api node dist/scripts/migrate.js
compose run --rm --no-deps api node dist/scripts/cleanup.js

if [ "${SEED_DEMO_DATA:-false}" = "true" ]; then
  compose run --rm --no-deps api node dist/scripts/seed.js
fi

compose up -d --remove-orphans

attempt=0
until curl --fail --silent --show-error \
  "http://127.0.0.1:${ROAD_DNA_PORT:-18080}/health" \
  | grep -q '"status":"ok"'; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 20 ]; then
    compose ps
    compose logs --tail=120 api dashboard
    echo "Road DNA failed its post-deployment health check." >&2
    exit 1
  fi
  sleep 3
done

compose ps
echo "Road DNA deployment is healthy."
