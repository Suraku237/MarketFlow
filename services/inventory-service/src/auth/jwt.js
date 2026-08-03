// Verifies tokens issued by auth-service. Both services share JWT_SECRET
// (set via env in docker-compose.yml) so inventory-service can independently
// confirm a token is genuine and read its role claim, without calling back
// to auth-service on every request.

const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required');
}

function verifyToken(token) {
  return jwt.verify(token, JWT_SECRET);
}

module.exports = { verifyToken };
