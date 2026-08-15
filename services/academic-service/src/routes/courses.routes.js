const { Router } = require('express');
const { authenticate, authorize } = require('../auth/middleware');
const { listCourses, getCourseById, createCourse } = require('../store');

const router = Router();

router.get('/', authenticate, async (req, res) => {
  const courses = await listCourses();
  res.json({ service: 'academic-service', courses });
});

router.get('/:id', authenticate, async (req, res) => {
  const course = await getCourseById(req.params.id);
  if (!course) {
    return res.status(404).json({ error: 'course not found' });
  }
  res.json({ service: 'academic-service', course });
});

router.post('/', authenticate, authorize('admin'), async (req, res) => {
  const { code, name, teacherId, credits, feeAmount, term } = req.body || {};

  if (!code || !name || feeAmount === undefined || !term) {
    return res.status(400).json({ error: 'code, name, feeAmount and term are required' });
  }

  try {
    const course = await createCourse({ code, name, teacherId, credits, feeAmount, term });
    res.status(201).json({ service: 'academic-service', course });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'a course with this code already exists' });
    }
    throw err;
  }
});

module.exports = router;
