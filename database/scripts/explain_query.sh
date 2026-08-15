#!/usr/bin/env bash
# Runs sample search queries against indexed columns and prints MySQL's
# EXPLAIN output, so you can point at the "key" column live in front of the
# examiner: a populated "key" (e.g. idx_enrollments_student) with type "ref"
# or "range" means the index was used; type "ALL" with key = NULL would mean
# a full table scan.
#
# Usage (from the repo root):
#   ./database/scripts/explain_query.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$DB_DIR/.." && pwd)"
# shellcheck source=./env.sh
source "$SCRIPT_DIR/env.sh"

cd "$REPO_ROOT"

echo "== Query: a student's enrollments (should use idx_enrollments_student) =="
docker compose exec -T "$DB_SERVICE" mysql -uroot -p"$DB_ROOT_PASSWORD" "$DB_NAME" \
  -e "EXPLAIN SELECT * FROM enrollments WHERE student_id = 1\G"

echo
echo "== Query: a student's invoices (should use idx_invoices_student) =="
docker compose exec -T "$DB_SERVICE" mysql -uroot -p"$DB_ROOT_PASSWORD" "$DB_NAME" \
  -e "EXPLAIN SELECT * FROM invoices WHERE student_id = 1\G"
