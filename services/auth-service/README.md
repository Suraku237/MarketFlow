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
database/
  schema.sql              Week 2: combined relational schema (SQLite, all modules)
  seed.sql                 Sample demo data
  scripts/
    init_db.sh              Create/reset the local SQLite database
    backup_db.sh             Timestamped backup via SQLite's .backup command
    restore_db.sh            Restore from the latest (or a chosen) backup
    explain_query.sh         Prove indexes are used (EXPLAIN QUERY PLAN)
  backups/                 Backup files land here (created at runtime, git-ignored)
  smartstock.db             The local SQLite database file (created at runtime, git-ignored)
documentation/
  main.tex / main.pdf                          Week 1-era Software Design Document
  SmartStock_Software_Design_Document.pdf       Same document, exported
  figures/                                      UML diagrams (use case, class, sequence, etc.)
  week2/
    week2_database_design.tex / .pdf             Week 2 write-up: ER diagram + relational schema
    er_diagram.puml                              PlantUML source for the ER diagram
    figures/er_diagram.png                       Rendered ER diagram
BRANCHING.md              Branch naming convention
docker-compose.yml         Brings up the auth-service
```

## Getting started — backend (auth-service)

```
docker compose up --build
```

Starts the auth service on `http://localhost:3000`. See
[`services/auth-service/README.md`](services/auth-service/README.md) for
endpoints and a demo script.

The React frontend lives in a separate repo (`marketflow_frontend`) with its
own `docker-compose.yml` — run this backend first, then `docker compose up
--build` there to get the webapp on `http://localhost:5173`. See that repo's
README for details.

## Getting started — database (Week 2, local SQLite)

The Week 2 database is developed against **SQLite 3** locally (no server
process required — the whole database is one file,
`database/smartstock.db`). The schema is written in plain SQL with only
SQLite-portable types, so it can later be pointed at MySQL/PostgreSQL for
production with minimal changes (see `documentation/week2/week2_database_design.pdf`,
§1.3).

Requires the `sqlite3` CLI (`apt install sqlite3` / `brew install sqlite3`).

```bash
# 1. Create the database from schema.sql and load sample data from seed.sql
./database/scripts/init_db.sh

# 2. Open it directly if you want to poke around
sqlite3 database/smartstock.db
sqlite> .tables
sqlite> .schema products
sqlite> SELECT * FROM products;
```

### Proving the indexes work

```bash
./database/scripts/explain_query.sh
```

Look for `SEARCH ... USING INDEX idx_...` in the output (rather than `SCAN`)
— that confirms SQLite used the index instead of scanning the whole table.

### Backup and restore (Week 2 evaluation)

```bash
# Take a backup
./database/scripts/backup_db.sh

# Simulate data loss
sqlite3 database/smartstock.db "DELETE FROM products;"

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