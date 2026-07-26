#!/usr/bin/env bash
# Runs a sample search query against an indexed column and shows SQLite's
# query plan, so you can point at "SEARCH ... USING INDEX idx_products_name"
# live in front of the examiner.
#
# Usage:
#   ./database/scripts/explain_query.sh [path/to/db]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_DIR="$(dirname "$SCRIPT_DIR")"
DB_PATH="${1:-$DB_DIR/smartstock.db}"

echo "== Query: search product by name (uses idx_products_name) =="
sqlite3 "$DB_PATH" "EXPLAIN QUERY PLAN SELECT * FROM products WHERE name = 'Sliced Bread';"

echo
echo "== Query: list a cashier's sales by date (uses idx_sales_sale_date) =="
sqlite3 "$DB_PATH" "EXPLAIN QUERY PLAN SELECT * FROM sales WHERE sale_date >= '2026-01-01' ORDER BY sale_date;"