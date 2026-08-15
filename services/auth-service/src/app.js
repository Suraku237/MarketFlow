const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth.routes');
const demoRoutes = require('./routes/demo.routes');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get('/health', (req, res) => res.json({ status: 'ok' }));

  app.get('/', (req, res) => res.json({
    service: 'smartschool-auth-service',
    endpoints: [
      'GET /health',
      'POST /api/auth/register',
      'POST /api/auth/login',
      'GET /api/auth/me',
      'GET /api/reports',
    ],
  }));

  app.use('/api/auth', authRoutes);
  app.use('/api', demoRoutes);

  app.use((req, res) => res.status(404).json({ error: 'not found' }));

  return app;
}

module.exports = { createApp };
