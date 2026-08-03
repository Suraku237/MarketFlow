// "Block a user after 10 requests in 1 minute": one shared limiter, applied
// to every request that reaches the Gateway (except /health, so container
// healthchecks/monitoring never trip it). Keyed by IP, since that's what
// identifies a client before they've necessarily logged in (register/login
// themselves count against the limit too).

const rateLimit = require('express-rate-limit');

const WINDOW_MS = Number(process.env.RATE_LIMIT_WINDOW_MS) || 60_000;
const MAX_REQUESTS = Number(process.env.RATE_LIMIT_MAX) || 10;

const limiter = rateLimit({
  windowMs: WINDOW_MS,
  max: MAX_REQUESTS,
  standardHeaders: true, // adds RateLimit-* response headers
  legacyHeaders: false,
  skip: (req) => req.path === '/health',
  handler: (req, res) => {
    res.status(429).json({
      error: 'Too many requests — rate limit exceeded',
      limit: MAX_REQUESTS,
      windowMs: WINDOW_MS,
    });
  },
});

module.exports = { limiter };
