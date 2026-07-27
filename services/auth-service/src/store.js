// SQLite-backed user store (Week 2). Reads/writes the `users` table defined
// in database/schema.sql through the connection opened in db.js.
//
// Routes and middleware are unchanged: they only call findByEmail() and
// createUser(), exactly as with the old in-memory store, so swapping the
// storage layer didn't require touching auth.routes.js or demo.routes.js.

const db = require('./db');

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

function findByEmail(email) {
  const row = db.prepare('SELECT * FROM users WHERE email = ?').get(email.toLowerCase());
  return rowToUser(row);
}

function createUser({ name, email, passwordHash, role }) {
  db.prepare(
    'INSERT INTO users (name, email, password_hash, role) VALUES (?, ?, ?, ?)'
  ).run(name, email.toLowerCase(), passwordHash, role);

  return findByEmail(email);
}

module.exports = { findByEmail, createUser };