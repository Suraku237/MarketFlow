#!/usr/bin/env bash
# (Re)creates the smartstock MySQL database from schema.sql + seed.sql,
# against the running `db` container. Safe to re-run: it drops and recreates
# the database first, so it always ends in the same known state — useful for
# resetting to a clean demo state before the evaluation.
#
# Usage (from the repo root, with `docker compose up -d db` already run or
# not — this script will start it if needed):
#   ./database/scripts/init_db.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$DB_DIR/.." && pwd)"
# shellcheck source=./env.sh
source "$SCRIPT_DIR/env.sh"

cd "$REPO_ROOT"

echo "Starting '$DB_SERVICE' if it isn't running..."
docker compose up -d "$DB_SERVICE"

echo "Waiting for MySQL to report healthy..."
CONTAINER_ID="$(docker compose ps -q "$DB_SERVICE")"
until [ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER_ID" 2>/dev/null)" = "healthy" ]; do
  sleep 2
done

echo "Dropping and recreating database '$DB_NAME'..."
docker compose exec -T "$DB_SERVICE" mysql -uroot -p"$DB_ROOT_PASSWORD" \
  -e "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;"

echo "Applying schema.sql..."
docker compose exec -T "$DB_SERVICE" mysql -uroot -p"$DB_ROOT_PASSWORD" "$DB_NAME" < "$DB_DIR/schema.sql"

echo "Loading seed.sql..."
docker compose exec -T "$DB_SERVICE" mysql -uroot -p"$DB_ROOT_PASSWORD" "$DB_NAME" < "$DB_DIR/seed.sql"

echo "Done. Tables:"
docker compose exec -T "$DB_SERVICE" mysql -uroot -p"$DB_ROOT_PASSWORD" "$DB_NAME" -e "SHOW TABLES;"
