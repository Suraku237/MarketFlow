// Connection pool for the shared SmartStock MySQL database (see
// database/schema.sql at the repo root, Week 2). Reads/writes the
// `products` table this service owns, on the same database auth-service
// uses for `users` — each service still only touches its own tables.

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
