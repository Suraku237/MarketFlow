#!/usr/bin/env bash
# Creates (or resets) the local SmartStock SQLite database from schema.sql,
# then loads sample data from seed.sql.
#
# Usage:
#   ./database/scripts/init_db.sh [path/to/db]
#
# Default DB path: database/smartstock.db

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="$(dirname "$SCRIPT_DIR")"
DB_PATH="${1:-$DB_DIR/smartstock.db}"

echo "Initializing SQLite database at: $DB_PATH"

if [ -f "$DB_PATH" ]; then
  echo "Existing database found — it will be recreated."
  rm -f "$DB_PATH"
fi

sqlite3 "$DB_PATH" < "$DB_DIR/schema.sql"
sqlite3 "$DB_PATH" < "$DB_DIR/seed.sql"

echo "Done. Tables created:"
sqlite3 "$DB_PATH" ".tables"