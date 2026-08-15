# SmartSchool Auth Service

Registration, login and role-based access control (Admin / Teacher / Student)
for SmartSchool, backed by bcrypt password hashing and JWT session tokens.

## Storage

Users are persisted in the shared MySQL database defined by
`database/schema.sql` at the repo root (Week 2) — the `users` table there is
the same one this service reads and writes via `src/db.js` (a `mysql2`
connection pool) and `src/store.js` (`findByEmail()` / `createUser()`).
Routes and middleware are unchanged from Week 1 — they still just call those
two functions, now async since MySQL is a network call rather than an
in-process store.

`docker compose up --build` from the repo root brings up a `db` (MySQL)
container that auto-applies `database/schema.sql` and `database/seed.sql` on
its first boot, and this service via `DB_HOST`/`DB_PORT`/`DB_USER`/
`DB_PASSWORD`/`DB_NAME` (see `docker-compose.yml`). To reset the database to
a clean state on demand, run `./database/scripts/init_db.sh` from the repo
root — see `database/scripts/` for that plus backup/restore/explain-query
scripts used in the Week 2 evaluation.

## Run it (one command)

From the repository root:

```
docker compose up --build
```

**Week 3 change:** this service is no longer published to the host — the
[API Gateway](../gateway/README.md) is now the only public entry point.
Reach these endpoints at `http://localhost:8081/api/v1/auth/...` and
`http://localhost:8081/api/v1/reports` instead of `localhost:3000` directly;
see the Gateway's README for the full routing table. The examples below
still show this service's own native paths (`/api/auth/...`), which is what
the Gateway rewrites requests to internally.

To run just this service standalone (e.g. for local development against a
locally installed MySQL instead of Docker):

```
docker build -t smartschool-auth . && docker run -p 3000:3000 --env-file .env smartschool-auth
```

## Running locally without Docker

```
npm install
cp .env.example .env
npm start
```

## Endpoints

| Method | Path              | Auth           | Description                          |
|--------|-------------------|----------------|---------------------------------------|
| GET    | `/health`         | none           | Liveness check                        |
| POST   | `/api/auth/register` | none        | Create a user (`name`, `email`, `password`, optional `role`: `admin` \| `teacher` \| `student`, defaults to `student`) |
| POST   | `/api/auth/login`    | none        | Returns a JWT + user profile          |
| GET    | `/api/auth/me`       | Bearer JWT  | Returns the identity encoded in the token |
| GET    | `/api/reports`       | Bearer JWT, role `admin` or `teacher` | Academic performance report — demo endpoint used to show live role changes |

## Demo script

All requests go through the Gateway on port `8081` now, not this service's
port `3000` directly.

```bash
# Register an admin
curl -s -X POST localhost:8081/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Ada Admin","email":"admin@smartschool.test","password":"adminpass123","role":"admin"}'

# Register a teacher
curl -s -X POST localhost:8081/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Tom Teacher","email":"teacher@smartschool.test","password":"teacherpass123","role":"teacher"}'

# Register a student
curl -s -X POST localhost:8081/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Sam Student","email":"student@smartschool.test","password":"studentpass123","role":"student"}'

# Log in as each and grab the token
ADMIN_TOKEN=$(curl -s -X POST localhost:8081/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@smartschool.test","password":"adminpass123"}' | jq -r .token)

TEACHER_TOKEN=$(curl -s -X POST localhost:8081/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"teacher@smartschool.test","password":"teacherpass123"}' | jq -r .token)

STUDENT_TOKEN=$(curl -s -X POST localhost:8081/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"student@smartschool.test","password":"studentpass123"}' | jq -r .token)

# Admin and Teacher can currently see the reports endpoint; Student cannot
curl -s localhost:8081/api/v1/reports -H "Authorization: Bearer $ADMIN_TOKEN"
curl -s localhost:8081/api/v1/reports -H "Authorization: Bearer $TEACHER_TOKEN"
curl -s localhost:8081/api/v1/reports -H "Authorization: Bearer $STUDENT_TOKEN"   # 403
```

## Live rule change (for the examiner)

To restrict `/api/reports` to Admins only, edit
[`src/routes/demo.routes.js`](src/routes/demo.routes.js) and change:

```js
router.get('/reports', authenticate, authorize('admin', 'teacher'), ...)
```

to:

```js
router.get('/reports', authenticate, authorize('admin'), ...)
```

Restart the process (`docker compose restart auth-service`) and re-run the
`curl` calls above (still through the Gateway on port `8081`) — the teacher
token now gets `403 Forbidden`, the admin token still works.

## How the security works (for the oral explanation)

- **Password protection**: passwords are never stored as plain text. On
  registration, `bcryptjs` runs the password through the bcrypt algorithm
  with a random salt and 10 hashing rounds (`src/auth/password.js`), producing
  a one-way hash that's stored instead of the password. On login, the same
  algorithm re-hashes the submitted password with the stored salt and
  compares hashes — the original password is never recoverable from what's
  stored, and even two users with the same password get different hashes
  because of the random salt.
- **Proving identity (JWT)**: on successful login, the server issues a JSON
  Web Token signed with a server-only secret (`src/auth/jwt.js`). The token's
  payload carries the user's id, email and role; its signature lets any
  request handler verify the token hasn't been tampered with, without
  needing to hit the database on every request. The client sends this token
  back in the `Authorization: Bearer <token>` header; `authenticate`
  middleware verifies the signature and expiry, and `authorize(...roles)`
  checks the role claim before letting the request through.
- **Week 3**: the [Gateway](../gateway/README.md) now does its own first-pass
  check — it verifies the same JWT (shared secret) before forwarding
  anything here at all, so an invalid/missing token never even reaches this
  service. This service's own `authenticate`/`authorize` still run too
  (defense in depth) — the Gateway confirms "logged in", this service still
  decides "allowed to do this specific thing".
