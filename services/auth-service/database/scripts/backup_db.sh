#!/usr/bin/env bash
# Creates a timestamped backup of the SmartStock SQLite database using
# SQLite's own ".backup" command (a safe, consistent copy — unlike a plain
# `cp`, this works correctly even while another process has the DB open).
#
# Usage:
#   ./database/scripts/backup_db.sh [path/to/db]
#
# Output: database/backups/smartstock_YYYYMMDD_HHMMSS.db

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="$(dirname "$SCRIPT_DIR")"
DB_PATH="${1:-$DB_DIR/smartstock.db}"
BACKUP_DIR="$DB_DIR/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="$BACKUP_DIR/smartstock_${TIMESTAMP}.db"

if [ ! -f "$DB_PATH" ]; then
  echo "No database found at $DB_PATH. Run init_db.sh first." >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"
sqlite3 "$DB_PATH" ".backup '$BACKUP_PATH'"

echo "Backup created: $BACKUP_PATH"