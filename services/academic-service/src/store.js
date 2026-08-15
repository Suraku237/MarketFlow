// Reads/writes the `students`/`courses`/`enrollments`/`grades` tables
// defined in database/schema.sql.

const pool = require('./db');

// ---------------------------------------------------------------------------
// Students
// ---------------------------------------------------------------------------

async function getStudentByUserId(userId) {
  const [rows] = await pool.query('SELECT * FROM students WHERE user_id = ?', [userId]);
  return rows[0];
}

// Students registered through auth-service's generic /auth/register only
// get a `users` row there — auth-service doesn't know about (and shouldn't
// have to know about) academic-service's `students` table. Rather than
// requiring a separate admin provisioning step before a newly-registered
// student can do anything, academic-service lazily creates a minimal
// student profile the first time one is needed.
async function getOrCreateStudentByUserId(userId) {
  const existing = await getStudentByUserId(userId);
  if (existing) return existing;

  await pool.query(
    `INSERT INTO students (user_id, admission_number, enrolled_on)
     VALUES (?, ?, CURDATE())`,
    [userId, `STU-${userId}`]
  );
  return getStudentByUserId(userId);
}

// ---------------------------------------------------------------------------
// Courses
// ---------------------------------------------------------------------------

async function listCourses() {
  const [rows] = await pool.query(
    `SELECT c.id, c.code, c.name, c.teacher_id, u.name AS teacher_name,
            c.credits, c.fee_amount, c.term
     FROM courses c
     LEFT JOIN users u ON u.id = c.teacher_id
     ORDER BY c.code`
  );
  return rows;
}

async function getCourseById(id) {
  const [rows] = await pool.query(
    `SELECT c.id, c.code, c.name, c.teacher_id, u.name AS teacher_name,
            c.credits, c.fee_amount, c.term
     FROM courses c
     LEFT JOIN users u ON u.id = c.teacher_id
     WHERE c.id = ?`,
    [id]
  );
  return rows[0];
}

async function createCourse({ code, name, teacherId, credits, feeAmount, term }) {
  const [result] = await pool.query(
    `INSERT INTO courses (code, name, teacher_id, credits, fee_amount, term)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [code, name, teacherId ?? null, credits ?? 3, feeAmount, term]
  );
  return getCourseById(result.insertId);
}

// ---------------------------------------------------------------------------
// Enrollments
// ---------------------------------------------------------------------------

async function listEnrollments({ studentId, courseId } = {}) {
  const conditions = [];
  const params = [];
  if (studentId) {
    conditions.push('e.student_id = ?');
    params.push(studentId);
  }
  if (courseId) {
    conditions.push('e.course_id = ?');
    params.push(courseId);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const [rows] = await pool.query(
    `SELECT e.id, e.student_id, su.name AS student_name, e.course_id,
            c.code AS course_code, c.name AS course_name, e.status, e.enrolled_at
     FROM enrollments e
     JOIN students s ON s.id = e.student_id
     JOIN users su ON su.id = s.user_id
     JOIN courses c ON c.id = e.course_id
     ${where}
     ORDER BY e.enrolled_at DESC`,
    params
  );
  return rows;
}

// Full detail for one enrollment — used both for the API response and (Week
// 4) as the payload published to RabbitMQ, so it includes everything needed
// to create an invoice without a follow-up lookup.
async function getEnrollmentDetails(enrollmentId) {
  const [rows] = await pool.query(
    `SELECT e.id AS enrollment_id, e.student_id, su.name AS student_name,
            su.email AS student_email, e.course_id, c.code AS course_code,
            c.name AS course_name, c.fee_amount, c.term, e.status, e.enrolled_at
     FROM enrollments e
     JOIN students s ON s.id = e.student_id
     JOIN users su ON su.id = s.user_id
     JOIN courses c ON c.id = e.course_id
     WHERE e.id = ?`,
    [enrollmentId]
  );
  return rows[0];
}

async function createEnrollment({ studentId, courseId }) {
  const [result] = await pool.query(
    'INSERT INTO enrollments (student_id, course_id) VALUES (?, ?)',
    [studentId, courseId]
  );
  return getEnrollmentDetails(result.insertId);
}

// ---------------------------------------------------------------------------
// Grades
// ---------------------------------------------------------------------------

async function listGrades({ studentId, teacherId, enrollmentId } = {}) {
  const conditions = [];
  const params = [];
  if (studentId) {
    conditions.push('s.id = ?');
    params.push(studentId);
  }
  if (teacherId) {
    conditions.push('c.teacher_id = ?');
    params.push(teacherId);
  }
  if (enrollmentId) {
    conditions.push('g.enrollment_id = ?');
    params.push(enrollmentId);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const [rows] = await pool.query(
    `SELECT g.id, g.enrollment_id, su.name AS student_name, c.code AS course_code,
            c.name AS course_name, g.assessment_type, g.score, g.recorded_at
     FROM grades g
     JOIN enrollments e ON e.id = g.enrollment_id
     JOIN students s ON s.id = e.student_id
     JOIN users su ON su.id = s.user_id
     JOIN courses c ON c.id = e.course_id
     ${where}
     ORDER BY g.recorded_at DESC`,
    params
  );
  return rows;
}

// Course a given enrollment belongs to, and who teaches it — used to check
// a teacher only records grades for their own courses.
async function getCourseIdForEnrollment(enrollmentId) {
  const [rows] = await pool.query(
    `SELECT c.id AS course_id, c.teacher_id
     FROM enrollments e
     JOIN courses c ON c.id = e.course_id
     WHERE e.id = ?`,
    [enrollmentId]
  );
  return rows[0];
}

async function createGrade({ enrollmentId, assessmentType, score, recordedBy }) {
  const [result] = await pool.query(
    `INSERT INTO grades (enrollment_id, assessment_type, score, recorded_by)
     VALUES (?, ?, ?, ?)`,
    [enrollmentId, assessmentType, score, recordedBy ?? null]
  );
  const [rows] = await pool.query('SELECT * FROM grades WHERE id = ?', [result.insertId]);
  return rows[0];
}

module.exports = {
  getStudentByUserId,
  getOrCreateStudentByUserId,
  listCourses,
  getCourseById,
  createCourse,
  listEnrollments,
  getEnrollmentDetails,
  createEnrollment,
  listGrades,
  getCourseIdForEnrollment,
  createGrade,
};
