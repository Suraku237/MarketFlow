// MySQL-backed user store (Week 2). Reads/writes the `users` table defined
// in database/schema.sql through the connection pool opened in db.js.
//
// Routes and middleware call findByEmail() / createUser() same as with the
// old in-memory store — only now they're async, since mysql2 is a network
// client rather than an in-process file.

const pool = require('./db');

function rowToUser(row) {
  if (!row) return undefined;
  return {
    id: row.id,
    name: row.name,
    email: row.email,
    passwordHash: row.password_hash,
    role: row.role,
    createdAt: row.created_at,
  };
}

async function findByEmail(email) {
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email.toLowerCase()]);
  return rowToUser(rows[0]);
}

async function createUser({ name, email, passwordHash, role }) {
  await pool.query(
    'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)',
    [name, email.toLowerCase(), passwordHash, role]
  );

  return findByEmail(email);
}

module.exports = { findByEmail, createUser };
