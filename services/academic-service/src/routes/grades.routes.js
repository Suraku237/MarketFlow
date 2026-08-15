const { Router } = require('express');
const { authenticate, authorize } = require('../auth/middleware');
const {
  getOrCreateStudentByUserId,
  listGrades,
  getCourseIdForEnrollment,
  createGrade,
} = require('../store');

const router = Router();

const ASSESSMENT_TYPES = ['quiz', 'assignment', 'midterm', 'final'];

router.get('/', authenticate, async (req, res) => {
  let { studentId } = req.query;
  let teacherId;

  if (req.user.role === 'student') {
    const student = await getOrCreateStudentByUserId(req.user.sub);
    studentId = student.id; // students can only ever see their own grades
  } else if (req.user.role === 'teacher') {
    teacherId = req.user.sub; // teachers only see grades for courses they teach
  }

  const grades = await listGrades({ studentId, teacherId });
  res.json({ service: 'academic-service', grades });
});

router.post('/', authenticate, authorize('admin', 'teacher'), async (req, res) => {
  const { enrollmentId, assessmentType, score } = req.body || {};

  if (!enrollmentId || !assessmentType || score === undefined) {
    return res.status(400).json({ error: 'enrollmentId, assessmentType and score are required' });
  }
  if (!ASSESSMENT_TYPES.includes(assessmentType)) {
    return res.status(400).json({ error: `assessmentType must be one of: ${ASSESSMENT_TYPES.join(', ')}` });
  }
  if (score < 0 || score > 100) {
    return res.status(400).json({ error: 'score must be between 0 and 100' });
  }

  if (req.user.role === 'teacher') {
    const course = await getCourseIdForEnrollment(enrollmentId);
    if (!course) {
      return res.status(400).json({ error: 'enrollmentId does not exist' });
    }
    if (course.teacher_id !== req.user.sub) {
      return res.status(403).json({ error: 'you can only record grades for courses you teach' });
    }
  }

  try {
    const grade = await createGrade({ enrollmentId, assessmentType, score, recordedBy: req.user.sub });
    res.status(201).json({ service: 'academic-service', grade });
  } catch (err) {
    if (err.code === 'ER_NO_REFERENCED_ROW_2') {
      return res.status(400).json({ error: 'enrollmentId does not exist' });
    }
    throw err;
  }
});

module.exports = router;
