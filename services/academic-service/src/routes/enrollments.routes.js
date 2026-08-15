const { Router } = require('express');
const { authenticate, authorize } = require('../auth/middleware');
const { getOrCreateStudentByUserId, listEnrollments, createEnrollment } = require('../store');
const { publishEnrollmentCreated } = require('../events/publisher');

const router = Router();

router.get('/', authenticate, async (req, res) => {
  let { studentId, courseId } = req.query;

  if (req.user.role === 'student') {
    const student = await getOrCreateStudentByUserId(req.user.sub);
    studentId = student.id; // students can only ever see their own enrollments
  }

  const enrollments = await listEnrollments({ studentId, courseId });
  res.json({ service: 'academic-service', enrollments });
});

router.post('/', authenticate, authorize('admin', 'student'), async (req, res) => {
  let studentId = req.body?.studentId;
  const { courseId } = req.body || {};

  if (req.user.role === 'student') {
    const student = await getOrCreateStudentByUserId(req.user.sub);
    studentId = student.id; // a student can only enroll themselves
  }

  if (!studentId || !courseId) {
    return res.status(400).json({ error: 'studentId and courseId are required' });
  }

  try {
    const enrollment = await createEnrollment({ studentId, courseId });

    // Fire-and-forget: publishEnrollmentCreated never throws and isn't
    // awaited for its broker round-trip — this response returns based on
    // the MySQL commit above, not on RabbitMQ or finance-service.
    publishEnrollmentCreated(enrollment);

    res.status(201).json({ service: 'academic-service', enrollment });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'this student is already enrolled in this course' });
    }
    if (err.code === 'ER_NO_REFERENCED_ROW_2') {
      return res.status(400).json({ error: 'studentId or courseId does not exist' });
    }
    throw err;
  }
});

module.exports = router;
