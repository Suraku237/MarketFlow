const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const { limiter } = require('./middleware/rateLimit');
const { requireAuth } = require('./middleware/auth');
const { toAuthService, toAcademicService } = require('./proxy');
const { loadCombinedSpec } = require('./docs');

function createApp() {
  const app = express();

  // No express.json() here on purpose: http-proxy-middleware needs the raw
  // request body stream to forward POST bodies untouched. The Gateway never
  // needs to read a body itself (the JWT it checks lives in a header).
  app.use(cors());
  app.use(limiter);

  app.get('/health', (req, res) => res.json({ status: 'ok', service: 'gateway' }));

  app.get('/', (req, res) => res.json({
    service: 'smartschool-gateway',
    routes: [
      'POST /api/v1/auth/register  -> auth-service',
      'POST /api/v1/auth/login     -> auth-service',
      'GET  /api/v1/auth/me        -> auth-service (JWT required)',
      'GET  /api/v1/reports        -> auth-service (JWT required)',
      'GET  /api/v1/courses        -> academic-service (JWT required)',
      'POST /api/v1/courses        -> academic-service (JWT required, Admin only)',
      'GET  /api/v1/enrollments    -> academic-service (JWT required)',
      'POST /api/v1/enrollments    -> academic-service (JWT required, Admin or Student)',
      'GET  /api/v1/grades         -> academic-service (JWT required)',
      'POST /api/v1/grades         -> academic-service (JWT required, Admin or Teacher)',
    ],
    docs: '/docs',
  }));

  app.use('/docs', swaggerUi.serve, swaggerUi.setup(loadCombinedSpec()));

  // Public — forwarded straight through, no login required yet.
  app.use('/api/v1/auth/register', toAuthService);
  app.use('/api/v1/auth/login', toAuthService);

  // Protected — the Gateway verifies the JWT itself before forwarding.
  // Role checks (e.g. Admin-only) are still enforced by whichever service
  // owns the resource; the Gateway only confirms "is logged in".
  app.use('/api/v1/auth/me', requireAuth, toAuthService);
  app.use('/api/v1/reports', requireAuth, toAuthService);
  app.use('/api/v1/courses', requireAuth, toAcademicService);
  app.use('/api/v1/enrollments', requireAuth, toAcademicService);
  app.use('/api/v1/grades', requireAuth, toAcademicService);

  app.use((req, res) => res.status(404).json({ error: 'not found' }));

  return app;
}

module.exports = { createApp };
