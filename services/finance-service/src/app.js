const express = require('express');
const cors = require('cors');
const invoicesRoutes = require('./routes/invoices.routes');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get('/health', (req, res) => res.json({ status: 'ok', service: 'finance-service' }));

  app.get('/', (req, res) => res.json({
    service: 'smartschool-finance-service',
    endpoints: [
      'GET /health',
      'GET /api/invoices',
    ],
    note: 'Also consumes "enrollment.created" from RabbitMQ to create invoices automatically.',
  }));

  app.use('/api/invoices', invoicesRoutes);

  app.use((req, res) => res.status(404).json({ error: 'not found' }));

  return app;
}

module.exports = { createApp };
