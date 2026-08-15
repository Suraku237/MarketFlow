# SmartSchool — OWASP Top 10 (Week 4)

Three risks from the OWASP Top 10, what's already done to mitigate each,
and the specific file/line that proves it — for the live evaluation
("explain one of your security protections and why it matters").

## 1. SQL Injection

**Mitigation**: every database query across every service uses `mysql2`'s
parameterized queries (`pool.query(sql, [params])`) — user input is always
passed as a bound parameter, never concatenated into the SQL string.

- `services/auth-service/src/store.js:23` — `pool.query('SELECT * FROM users WHERE email = ?', [email.toLowerCase()])`
- `services/academic-service/src/store.js` — every query in `listCourses`,
  `createEnrollment`, `listGrades`, etc. follows the same pattern, including
  the dynamically-built `WHERE` clauses in `listEnrollments`/`listGrades`
  (`store.js:77-93`, `:134-155`) — the *column conditions* like
  `'e.student_id = ?'` are fixed strings assembled at runtime, but the
  *values* going into them are always still bound via the `params` array,
  never interpolated directly.
- `services/finance-service/src/store.js:18-27` — same pattern for
  `listInvoices`.

Verified by grep: no store.js in the codebase builds a SQL string via
template-literal interpolation of a request value.

**Why it matters**: without parameterization, something as simple as a
student registering with an email containing a `'` could corrupt or bypass
a query. Binding parameters makes the database treat input as *data*,
never as *code*, regardless of what's in it.

## 2. Broken Authentication

**Mitigation**: passwords are hashed with bcrypt before storage
(`services/auth-service/src/auth/password.js`, 10 salt rounds — never
stored or logged in plain text), sessions are stateless signed JWTs with a
1-hour expiry (`services/auth-service/src/auth/jwt.js`), and the Gateway
verifies every protected request's JWT signature and expiry *before*
forwarding it anywhere (`services/gateway/src/middleware/auth.js`) — an
invalid or missing token never reaches a backend service at all.

A second layer comes for free: the Gateway's rate limiter
(`services/gateway/src/middleware/rateLimit.js`, 10 requests/60s per IP)
applies to *every* route except `/health` — including
`/api/v1/auth/login` — so it doubles as brute-force login throttling
without any dedicated code for it.

**Accepted gap**: password policy is length ≥ 8 characters only
(`services/auth-service/src/routes/auth.routes.js`), no complexity
requirement. Documented here as a deliberate scope limit for this project
rather than left unmentioned — adding complexity rules wasn't judged worth
the added friction for a course demo system.

## 3. Sensitive Data Exposure

**Mitigation**: `password_hash` is never returned in any API response —
`services/auth-service/src/routes/auth.routes.js`'s `toPublicUser()`
destructures it out of every user object before sending a response
(`const { passwordHash, ...publicUser } = user;`), used by both
`/register` and `/login`.

**Accepted gap**: CORS is currently open (`app.use(cors())` with no origin
allowlist, in every service and the Gateway). Documented as a deliberate,
low-severity tradeoff: this is a Bearer-token API (the JWT lives in an
`Authorization` header the frontend sets explicitly), not a cookie-based
session, so there's no ambient-credential CSRF exposure the way a
cookie-authenticated API would have — a malicious page can't make the
browser silently attach a valid token to a cross-origin request the way it
could with a cookie. Optional (not required for this mark) hardening: add
a `FRONTEND_ORIGIN` allowlist at the Gateway only, so `cors()` there
restricts to `http://localhost:5173` in dev / the deployed frontend origin
in production.
