#!/usr/bin/env bash
# Creates a timestamped mysqldump backup of the smartstock database.
#
# Usage (from the repo root):
#   ./database/scripts/backup_db.sh
#
# Output: database/backups/smartstock_YYYYMMDD_HHMMSS.sql

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$DB_DIR/.." && pwd)"
# shellcheck source=./env.sh
source "$SCRIPT_DIR/env.sh"

cd "$REPO_ROOT"

BACKUP_DIR="$DB_DIR/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="$BACKUP_DIR/smartstock_${TIMESTAMP}.sql"
mkdir -p "$BACKUP_DIR"

echo "Backing up '$DB_NAME' from the '$DB_SERVICE' container..."
docker compose exec -T "$DB_SERVICE" mysqldump --no-tablespaces -uroot -p"$DB_ROOT_PASSWORD" "$DB_NAME" > "$BACKUP_PATH"

echo "Backup created: $BACKUP_PATH"
