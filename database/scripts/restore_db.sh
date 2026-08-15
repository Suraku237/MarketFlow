#!/usr/bin/env bash
# Restores the smartschool database from a mysqldump backup created by
# backup_db.sh. If no backup file is given, the most recent one in
# database/backups/ is used.
#
# Usage (from the repo root):
#   ./database/scripts/restore_db.sh [path/to/backup.sql]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$DB_DIR/.." && pwd)"
# shellcheck source=./env.sh
source "$SCRIPT_DIR/env.sh"

cd "$REPO_ROOT"

BACKUP_DIR="$DB_DIR/backups"
BACKUP_PATH="${1:-}"
if [ -z "$BACKUP_PATH" ]; then
  BACKUP_PATH="$(ls -t "$BACKUP_DIR"/smartschool_*.sql 2>/dev/null | head -n 1 || true)"
fi

if [ -z "$BACKUP_PATH" ] || [ ! -f "$BACKUP_PATH" ]; then
  echo "No backup file found. Run backup_db.sh first, or pass a path explicitly." >&2
  exit 1
fi

echo "Restoring '$DB_NAME' from: $BACKUP_PATH"
docker compose exec -T "$DB_SERVICE" mysql -uroot -p"$DB_ROOT_PASSWORD" "$DB_NAME" < "$BACKUP_PATH"

echo "Restore complete. Row counts after restore:"
for t in users students courses enrollments grades invoices payroll_runs payslips; do
  count=$(docker compose exec -T "$DB_SERVICE" mysql -uroot -p"$DB_ROOT_PASSWORD" "$DB_NAME" -N -e "SELECT COUNT(*) FROM $t;" | tr -d '\r')
  printf "  %-20s %s\n" "$t" "$count"
done
