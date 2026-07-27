// Opens the SmartStock SQLite database (database/schema.sql defines the
// tables). Auth-service reads/writes the `users` table through this
// connection instead of the old in-memory Map (see store.js).
//
// DB_PATH can be overridden with an env var (used in docker-compose so the
// container points at a mounted volume). Locally it defaults to the shared
// database/smartstock.db at the repo root, three levels up from this file
// (src -> auth-service -> services -> repo root).

const path = require('path');
const fs = require('fs');
const Database = require('better-sqlite3');

const DB_PATH =
  process.env.DB_PATH || path.resolve(__dirname, '..', '..', '..', 'database', 'smartstock.db');

const SCHEMA_PATH = path.join(path.dirname(DB_PATH), 'schema.sql');

// Make sure the directory for the database file exists (first run / fresh
// docker volume won't have it yet).
fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });

const db = new Database(DB_PATH);
db.pragma('foreign_keys = ON');
db.pragma('journal_mode = WAL');

// Applying schema.sql is safe to repeat: every statement in it is
// `CREATE TABLE IF NOT EXISTS` / `CREATE INDEX IF NOT EXISTS`, so this never
// touches existing data — it only fills in tables on a brand-new database
// file (e.g. the first time a fresh Docker volume is mounted).
if (fs.existsSync(SCHEMA_PATH)) {
  db.exec(fs.readFileSync(SCHEMA_PATH, 'utf8'));
} else {
  console.warn(`[db] schema.sql not found at ${SCHEMA_PATH} — assuming the database is already set up`);
}

console.log(`[db] using SQLite database at ${DB_PATH}`);

module.exports = db;