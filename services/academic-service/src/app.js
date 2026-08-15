const express = require('express');
const cors = require('cors');
const coursesRoutes = require('./routes/courses.routes');
const enrollmentsRoutes = require('./routes/enrollments.routes');
const gradesRoutes = require('./routes/grades.routes');

function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  app.get('/health', (req, res) => res.json({ status: 'ok', service: 'academic-service' }));

  app.get('/', (req, res) => res.json({
    service: 'smartschool-academic-service',
    endpoints: [
      'GET /health',
      'GET /api/courses',
      'GET /api/courses/:id',
      'POST /api/courses',
      'GET /api/enrollments',
      'POST /api/enrollments',
      'GET /api/grades',
      'POST /api/grades',
    ],
  }));

  app.use('/api/courses', coursesRoutes);
  app.use('/api/enrollments', enrollmentsRoutes);
  app.use('/api/grades', gradesRoutes);

  app.use((req, res) => res.status(404).json({ error: 'not found' }));

  return app;
}

module.exports = { createApp };
