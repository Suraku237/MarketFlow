// Reads/writes the `invoices` table defined in database/schema.sql.
// Also reads `students` (owned by academic-service) to translate a
// Student's JWT `sub` (a users.id) into a students.id for scoping — the
// same cross-service read pattern academic-service already uses for
// `users` (owned by auth-service).

const pool = require('./db');

async function getStudentIdByUserId(userId) {
  const [rows] = await pool.query('SELECT id FROM students WHERE user_id = ?', [userId]);
  return rows[0]?.id;
}

async function listInvoices({ studentId } = {}) {
  const conditions = [];
  const params = [];
  if (studentId) {
    conditions.push('i.student_id = ?');
    params.push(studentId);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const [rows] = await pool.query(
    `SELECT i.id, i.student_id, i.enrollment_id, i.amount, i.momo_reference,
            i.method, i.status, i.issued_at, i.paid_at
     FROM invoices i
     ${where}
     ORDER BY i.issued_at DESC`,
    params
  );
  return rows;
}

async function getInvoiceById(id) {
  const [rows] = await pool.query('SELECT * FROM invoices WHERE id = ?', [id]);
  return rows[0];
}

async function createInvoice({ studentId, enrollmentId, amount }) {
  const [result] = await pool.query(
    `INSERT INTO invoices (student_id, enrollment_id, amount, status)
     VALUES (?, ?, ?, 'pending')`,
    [studentId, enrollmentId, amount]
  );
  return getInvoiceById(result.insertId);
}

module.exports = { getStudentIdByUserId, listInvoices, getInvoiceById, createInvoice };
