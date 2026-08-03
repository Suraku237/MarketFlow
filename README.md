# MarketFlow — SmartStock

Supermarket Inventory, Sales Prediction & Payroll Management System.
Practical exam project for **SEN4121 — Large System Environment**, ICT
University Yaoundé (Examiner: Engr. Tanwi Nkiamboh).

The full software design document (use cases, class diagram, sequence
diagrams, etc.) is in [`documentation/main.pdf`](documentation/) /
[`documentation/SmartStock_Software_Design_Document.pdf`](documentation/SmartStock_Software_Design_Document.pdf).

## Repository layout

```
services/
  auth-service/          Week 1: registration, login, JWT, role-based access
  inventory-service/     Week 3 module service: product catalog
  gateway/                Week 3: API Gateway — single entry point, routing, JWT check, rate limit
database/
  schema.sql              Week 2: combined relational schema (MySQL, all modules)
  seed.sql                 Sample demo data
  scripts/
    env.sh                  Shared config (db service name, credentials) for the scripts below
    init_db.sh              Reset the database to a clean state from schema.sql + seed.sql
    backup_db.sh             Timestamped backup via mysqldump
    restore_db.sh            Restore from the latest (or a chosen) backup
    explain_query.sh         Prove indexes are used (EXPLAIN)
  backups/                 Backup files land here (created at runtime, git-ignored)
documentation/
  main.tex / main.pdf                          Week 1-era Software Design Document
  SmartStock_Software_Design_Document.pdf       Same document, exported
  figures/                                      UML diagrams (use case, class, sequence, etc.)
  week2/
    week2_database_design.tex / .pdf             Week 2 write-up: ER diagram + relational schema
    er_diagram.puml                              PlantUML source for the ER diagram
    figures/er_diagram.png                       Rendered ER diagram
BRANCHING.md              Branch naming convention
docker-compose.yml         Brings up MySQL, auth-service, inventory-service and the Gateway
```

## Getting started — backend + database

```
docker compose up --build
```

This one command brings up four containers: `db` (MySQL 8, with
`database/schema.sql` and `database/seed.sql` applied automatically the
first time its data volume is created), `auth-service`, `inventory-service`,
and the `gateway`. **Only the Gateway is published to your machine** — at
`http://localhost:8081` — the other three are internal-only, reachable from
each other over the Docker network but not from your host directly. See
[`services/gateway/README.md`](services/gateway/README.md) for the full
routing table, and [`services/auth-service/README.md`](services/auth-service/README.md) /
[`services/inventory-service/README.md`](services/inventory-service/README.md)
for what each service does on its own.

The React frontend lives in a separate repo (`marketflow_frontend`) with its
own `docker-compose.yml` — run this backend first, then `docker compose up
--build` there to get the webapp on `http://localhost:5173`, pointed at the
Gateway. See that repo's README for details.

## Week 3: microservices behind an API Gateway

```
curl http://localhost:8081/docs           # combined Swagger UI for every endpoint
curl http://localhost:8081/api/v1/reports -H "Authorization: Bearer $TOKEN"   # -> auth-service
curl http://localhost:8081/api/v1/products -H "Authorization: Bearer $TOKEN"  # -> inventory-service
```

Both routes above go through the same Gateway on the same port; the
`service` field in each JSON response shows which backend actually handled
it. See [`services/gateway/README.md`](services/gateway/README.md) for the
routing table, how the Gateway checks a request is authenticated before
forwarding it, and the rate-limit demo (10 requests/minute, 11th gets `429`).

## Working with the database directly (Week 2)

All scripts run from the repo root and talk to the `db` container via
`docker compose exec` — no local MySQL client install needed.

```bash
# Reset the database to a clean, known state (drops + recreates it from
# schema.sql + seed.sql)
./database/scripts/init_db.sh

# Open a shell inside the database directly if you want to poke around
docker compose exec db mysql -uroot -pdev-only-change-me smartstock
mysql> SHOW TABLES;
mysql> SELECT * FROM products;
```

### Proving the indexes work

```bash
./database/scripts/explain_query.sh
```

Look at the `key` column in MySQL's `EXPLAIN` output — a populated key (e.g.
`idx_products_name`) with `type` `ref`/`range` means the index was used;
`type: ALL` with `key: NULL` would mean a full table scan.

### Backup and restore (Week 2 evaluation)

```bash
# Take a backup
./database/scripts/backup_db.sh

# Simulate data loss
docker compose exec db mysql -uroot -pdev-only-change-me smartstock -e "DELETE FROM products;"

# Restore from the most recent backup
./database/scripts/restore_db.sh
```

`restore_db.sh` prints row counts for every table after restoring, so you can
show the examiner the data is back exactly as it was.

## Week 2 documentation

[`documentation/week2/week2_database_design.pdf`](documentation/week2/week2_database_design.pdf)
contains, in one document:

- A single combined **Entity-Relationship Diagram** (all 10 tables across the
  Inventory, Sales, and Staff & Payroll modules), authored in PlantUML
  (`er_diagram.puml`).
- The full **relational schema**, table by table, with types and constraints.
- The **3NF normalization rationale**, including the two deliberate
  "denormalized-looking" columns (`sale_items.unit_price` as a price
  snapshot, `sales.total_amount` as a cached aggregate) and why they don't
  violate 3NF.
- The **indexing strategy** (8 indexes across the schema, more than the
  2-index minimum required).
- The **backup/restore procedure** used for the live evaluation.

## Contributing

See [`BRANCHING.md`](BRANCHING.md) for the branch naming rule. Branch off
`main`, open a pull request, get it reviewed, merge.
