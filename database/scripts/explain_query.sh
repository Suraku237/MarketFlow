#!/usr/bin/env bash
# Runs sample search queries against indexed columns and prints MySQL's
# EXPLAIN output, so you can point at the "key" column live in front of the
# examiner: a populated "key" (e.g. idx_products_name) with type "ref" or
# "range" means the index was used; type "ALL" with key = NULL would mean a
# full table scan.
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

echo "== Query: search product by name (should use idx_products_name) =="
docker compose exec -T "$DB_SERVICE" mysql -uroot -p"$DB_ROOT_PASSWORD" "$DB_NAME" \
  -e "EXPLAIN SELECT * FROM products WHERE name = 'Sliced Bread'\G"

echo
echo "== Query: list sales by date (should use idx_sales_sale_date) =="
docker compose exec -T "$DB_SERVICE" mysql -uroot -p"$DB_ROOT_PASSWORD" "$DB_NAME" \
  -e "EXPLAIN SELECT * FROM sales WHERE sale_date >= '2026-01-01' ORDER BY sale_date\G"
