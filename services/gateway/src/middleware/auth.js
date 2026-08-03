// The Gateway's own "is this user logged in" check, run BEFORE a protected
// request is forwarded anywhere. It only verifies the JWT's signature and
// expiry (shared JWT_SECRET with auth-service/inventory-service) — it does
// NOT check roles. Role checks (e.g. "admin only") stay in whichever
// downstream service owns that resource, so each service keeps control of
// its own authorization rules; the Gateway's job is just the front door.

const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required');
}

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Missing or malformed Authorization header' });
  }

  try {
    jwt.verify(token, JWT_SECRET);
    // Valid token — forward the request (with its original Authorization
    // header) to whichever service owns the resource. We don't rewrite the
    // header or attach req.user here: the downstream service decodes the
    // token itself if it needs the role/identity claims.
    return next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = { requireAuth };
