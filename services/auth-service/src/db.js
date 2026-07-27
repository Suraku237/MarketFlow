// Connection pool for the shared SmartStock MySQL database (see
// database/schema.sql at the repo root, Week 2). auth-service reads/writes
// the `users` table through this pool instead of the old in-memory Map
// (see store.js).
//
// All connection details come from env vars, matching the `db` service in
// the root docker-compose.yml — see .env.example for local (non-Docker) dev.

const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'dev-only-change-me',
  database: process.env.DB_NAME || 'smartstock',
  waitForConnections: true,
  connectionLimit: 10,
});

module.exports = pool;
