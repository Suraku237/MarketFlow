const express = require('express');
const cors = require('cors');
const productsRoutes = require('./routes/products.routes');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get('/health', (req, res) => res.json({ status: 'ok', service: 'inventory-service' }));

  app.get('/', (req, res) => res.json({
    service: 'smartstock-inventory-service',
    endpoints: [
      'GET /health',
      'GET /api/products',
      'GET /api/products/:id',
      'POST /api/products',
    ],
  }));

  app.use('/api/products', productsRoutes);

  app.use((req, res) => res.status(404).json({ error: 'not found' }));

  return app;
}

module.exports = { createApp };
