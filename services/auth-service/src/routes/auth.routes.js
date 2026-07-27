const { Router } = require('express');
const { findByEmail, createUser } = require('../store');
const { hashPassword, verifyPassword } = require('../auth/password');
const { signToken } = require('../auth/jwt');
const { authenticate } = require('../auth/middleware');
const { ROLES } = require('../auth/roles');

const router = Router();

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function toPublicUser(user) {
  const { passwordHash, ...publicUser } = user;
  return publicUser;
}

router.post('/register', async (req, res) => {
  const { name, email, password, role } = req.body || {};

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'name, email and password are required' });
  }
  if (!EMAIL_RE.test(email)) {
    return res.status(400).json({ error: 'email is not valid' });
  }
  if (password.length < 8) {
    return res.status(400).json({ error: 'password must be at least 8 characters' });
  }
  const finalRole = role || 'cashier';
  if (!ROLES.includes(finalRole)) {
    return res.status(400).json({ error: `role must be one of: ${ROLES.join(', ')}` });
  }
  if (await findByEmail(email)) {
    return res.status(409).json({ error: 'a user with this email already exists' });
  }

  const passwordHash = await hashPassword(password);
  let user;
  try {
    user = await createUser({ name, email, passwordHash, role: finalRole });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'a user with this email already exists' });
    }
    throw err;
  }

  return res.status(201).json({ user: toPublicUser(user) });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body || {};

  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required' });
  }

  const user = await findByEmail(email);
  const passwordMatches = user ? await verifyPassword(password, user.passwordHash) : false;

  if (!user || !passwordMatches) {
    return res.status(401).json({ error: 'invalid email or password' });
  }

  const token = signToken(user);
  return res.json({ token, user: toPublicUser(user) });
});

router.get('/me', authenticate, (req, res) => {
  return res.json({ user: req.user });
});

module.exports = router;
