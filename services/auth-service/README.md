# SmartStock Auth Service

Registration, login and role-based access control (Admin / Cashier) for
SmartStock, backed by bcrypt password hashing and JWT session tokens.

## Run it (one command)

From the repository root:

```
docker compose up --build
```

The service starts on `http://localhost:3000` with a working `JWT_SECRET`
already set (see `docker-compose.yml`). No `.env` file needed for a demo.

Alternatively, from this directory:

```
docker build -t smartstock-auth . && docker run -p 3000:3000 smartstock-auth
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
| POST   | `/api/auth/register` | none        | Create a user (`name`, `email`, `password`, optional `role`: `admin` \| `cashier`, defaults to `cashier`) |
| POST   | `/api/auth/login`    | none        | Returns a JWT + user profile          |
| GET    | `/api/auth/me`       | Bearer JWT  | Returns the identity encoded in the token |
| GET    | `/api/reports`       | Bearer JWT, role `admin` or `cashier` | Demo endpoint used to show live role changes |

## Demo script

```bash
# Register an admin
curl -s -X POST localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Ada Admin","email":"admin@smartstock.test","password":"adminpass123","role":"admin"}'

# Register a cashier
curl -s -X POST localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Cara Cashier","email":"cashier@smartstock.test","password":"cashierpass123","role":"cashier"}'

# Log in as each and grab the token
ADMIN_TOKEN=$(curl -s -X POST localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@smartstock.test","password":"adminpass123"}' | jq -r .token)

CASHIER_TOKEN=$(curl -s -X POST localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"cashier@smartstock.test","password":"cashierpass123"}' | jq -r .token)

# Both can currently see the reports endpoint
curl -s localhost:3000/api/reports -H "Authorization: Bearer $ADMIN_TOKEN"
curl -s localhost:3000/api/reports -H "Authorization: Bearer $CASHIER_TOKEN"
```

## Live rule change (for the examiner)

To restrict `/api/reports` to Admins only, edit
[`src/routes/demo.routes.js`](src/routes/demo.routes.js) and change:

```js
router.get('/reports', authenticate, authorize('admin', 'cashier'), ...)
```

to:

```js
router.get('/reports', authenticate, authorize('admin'), ...)
```

Restart the process (or `docker compose restart`) and re-run the two `curl`
calls above — the cashier token now gets `403 Forbidden`, the admin token
still works.

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
