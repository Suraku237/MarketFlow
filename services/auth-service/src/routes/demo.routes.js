// Demo endpoint used to show role-based access control live: it currently allows
// both Admin and Teacher, so it can be tightened to Admin-only in front of the
// examiner by editing the authorize(...) list below. See services/auth-service/README.md.

const { Router } = require('express');
const { authenticate, authorize } = require('../auth/middleware');

const router = Router();

router.get('/reports', authenticate, authorize('admin', 'teacher'), (req, res) => {
  res.json({
    service: 'auth-service',
    message: `Academic performance report visible to ${req.user.role}`,
    requestedBy: req.user.email,
  });
});

module.exports = router;
