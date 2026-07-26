#!/usr/bin/env bash
# Restores the SmartStock SQLite database from a backup file created by
# backup_db.sh. If no backup file is given, the most recent one in
# database/backups/ is used.
#
# Usage:
#   ./database/scripts/restore_db.sh [path/to/backup.db] [path/to/db]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$DB_DIR/backups"
DB_PATH="${2:-$DB_DIR/smartstock.db}"

BACKUP_PATH="${1:-}"
if [ -z "$BACKUP_PATH" ]; then
  BACKUP_PATH="$(ls -t "$BACKUP_DIR"/smartstock_*.db 2>/dev/null | head -n 1 || true)"
fi

if [ -z "$BACKUP_PATH" ] || [ ! -f "$BACKUP_PATH" ]; then
  echo "No backup file found. Run backup_db.sh first, or pass a path explicitly." >&2
  exit 1
fi

echo "Restoring from: $BACKUP_PATH"
echo "Target database: $DB_PATH"

sqlite3 "$DB_PATH" ".restore '$BACKUP_PATH'"

echo "Restore complete. Row counts after restore:"
for t in users categories suppliers products stock_movements sales sale_items payments demand_forecasts payroll_runs payslips; do
  count=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM $t;")
  printf "  %-20s %s\n" "$t" "$count"
done