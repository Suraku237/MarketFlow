const { Router } = require('express');
const { authenticate } = require('../auth/middleware');
const { getStudentIdByUserId, listInvoices } = require('../store');

const router = Router();

router.get('/', authenticate, async (req, res) => {
  let { studentId } = req.query;

  if (req.user.role === 'student') {
    const ownStudentId = await getStudentIdByUserId(req.user.sub);
    if (!ownStudentId) {
      return res.json({ service: 'finance-service', invoices: [] }); // no profile yet -> no invoices yet
    }
    studentId = ownStudentId; // students can only ever see their own invoices
  }

  const invoices = await listInvoices({ studentId });
  res.json({ service: 'finance-service', invoices });
});

module.exports = router;
