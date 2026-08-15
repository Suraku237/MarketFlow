// Forwarding rules: which URL prefix goes to which backend service.
// This is the Gateway's actual "front door" logic — clients only ever see
// /api/v1/..., never the individual services directly.

const { createProxyMiddleware } = require('http-proxy-middleware');

const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://localhost:3000';
const ACADEMIC_SERVICE_URL = process.env.ACADEMIC_SERVICE_URL || 'http://localhost:4000';
const FINANCE_SERVICE_URL = process.env.FINANCE_SERVICE_URL || 'http://localhost:4001';

// pathRewrite is a function, not a regex map, because these proxies are
// mounted with app.use('/some/exact/path', proxy) — Express strips that
// matched mount path from req.url before the proxy ever sees it, so a
// regex keyed on the original prefix would never match. req.originalUrl is
// untouched by that stripping, so we rewrite from there instead.
const toAuthService = createProxyMiddleware({
  target: AUTH_SERVICE_URL,
  changeOrigin: true,
  pathRewrite: (_path, req) =>
    req.originalUrl
      .replace(/^\/api\/v1\/auth/, '/api/auth')
      .replace(/^\/api\/v1\/reports/, '/api/reports'),
});

const toAcademicService = createProxyMiddleware({
  target: ACADEMIC_SERVICE_URL,
  changeOrigin: true,
  pathRewrite: (_path, req) =>
    req.originalUrl
      .replace(/^\/api\/v1\/courses/, '/api/courses')
      .replace(/^\/api\/v1\/enrollments/, '/api/enrollments')
      .replace(/^\/api\/v1\/grades/, '/api/grades'),
});

const toFinanceService = createProxyMiddleware({
  target: FINANCE_SERVICE_URL,
  changeOrigin: true,
  pathRewrite: (_path, req) => req.originalUrl.replace(/^\/api\/v1\/finance/, '/api'),
});

module.exports = { toAuthService, toAcademicService, toFinanceService };
