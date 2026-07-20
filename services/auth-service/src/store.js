// In-memory user store for Week 1. Swap for a real database (Postgres) in a later sprint
// without touching routes/middleware — they only talk to the functions exported here.

const usersByEmail = new Map();
let nextId = 1;

function findByEmail(email) {
  return usersByEmail.get(email.toLowerCase());
}

function createUser({ name, email, passwordHash, role }) {
  const user = {
    id: nextId++,
    name,
    email: email.toLowerCase(),
    passwordHash,
    role,
    createdAt: new Date().toISOString(),
  };
  usersByEmail.set(user.email, user);
  return user;
}

module.exports = { findByEmail, createUser };
