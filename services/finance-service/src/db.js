// Connection pool for the shared SmartSchool MySQL database (see
// database/schema.sql at the repo root, Week 2). Reads/writes the
// `invoices` table this service owns, on the same database auth-service
// and academic-service use for their own tables.

const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'dev-only-change-me',
  database: process.env.DB_NAME || 'smartschool',
  waitForConnections: true,
  connectionLimit: 10,
});

module.exports = pool;
