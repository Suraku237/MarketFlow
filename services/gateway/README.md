# SmartStock API Gateway

Single entry point for the whole system (Week 3). External clients — the
frontend, curl, Postman, the examiner — only ever talk to the Gateway.
`auth-service` and `inventory-service` have no port published to the host at
all; the only way to reach them is through here.

## Routing table

| Path (external)         | Forwarded to                        | Auth required? |
|--------------------------|--------------------------------------|----------------|
| `POST /api/v1/auth/register` | `auth-service` `/api/auth/register` | No |
| `POST /api/v1/auth/login`    | `auth-service` `/api/auth/login`    | No |
| `GET /api/v1/auth/me`        | `auth-service` `/api/auth/me`       | Yes |
| `GET /api/v1/reports`        | `auth-service` `/api/reports`       | Yes |
| `GET /api/v1/products`       | `inventory-service` `/api/products` | Yes |
| `GET /api/v1/products/:id`   | `inventory-service` `/api/products/:id` | Yes |
| `POST /api/v1/products`      | `inventory-service` `/api/products` | Yes (Admin only) |

Routing is done with `http-proxy-middleware` in [`src/proxy.js`](src/proxy.js) —
each downstream service gets one proxy instance with a `pathRewrite` rule;
`src/app.js` mounts each external path onto the right proxy.

## How the Gateway checks you're logged in (for the oral evaluation)

[`src/middleware/auth.js`](src/middleware/auth.js) — `requireAuth` — runs
**before** the proxy, only on routes that need it. It reads the
`Authorization: Bearer <token>` header and verifies the JWT's signature and
expiry using the same `JWT_SECRET` that `auth-service` signed it with (shared
via env var across all three services). If verification fails, the Gateway
responds `401` immediately and the request never reaches the backend at all.
If it succeeds, the original request — including its `Authorization` header —
is forwarded unchanged.

Deliberately out of scope for the Gateway: **role** checks (Admin vs Cashier).
That stays with whichever service owns the resource (`authorize('admin')` in
`inventory-service`'s `POST /api/products`, same pattern as Week 1's
`/api/reports` in `auth-service`) — the Gateway only answers "is this a
logged-in user at all", not "are they allowed to do this specific thing".
That's a deliberate separation: the Gateway is generic infrastructure, role
rules are business logic that belongs to the service that owns the data.

## Rate limiting

[`src/middleware/rateLimit.js`](src/middleware/rateLimit.js) — `express-rate-limit`,
applied to every request except `/health`. Default: **10 requests per 60
seconds per IP** (`RATE_LIMIT_MAX` / `RATE_LIMIT_WINDOW_MS` env vars). The
11th request in a window gets `429` with a JSON body explaining the limit,
plus standard `RateLimit-*` response headers showing the remaining quota.

## API docs

`GET /docs` serves a combined Swagger UI for every endpoint reachable through
the Gateway (both `auth-service`'s and `inventory-service`'s), built from the
two OpenAPI specs in [`openapi/`](openapi/). Open
`http://localhost:8081/docs` once the stack is running — "Try it out" calls
go through the real, running Gateway.

## Run it

From the repo root:

```
docker compose up --build
```

Brings up `db`, `auth-service`, `inventory-service` and this Gateway
together; only the Gateway's port (`8081` on the host, `8080` inside its
container) is published to your machine.

## Demo script

```bash
# Register + log in (public routes, no rate limit exemption though — they
# count toward the same 10/min budget as everything else)
curl -s -X POST localhost:8081/api/v1/auth/register -H "Content-Type: application/json" \
  -d '{"name":"Ada Admin","email":"admin@smartstock.test","password":"adminpass123","role":"admin"}'

TOKEN=$(curl -s -X POST localhost:8081/api/v1/auth/login -H "Content-Type: application/json" \
  -d '{"email":"admin@smartstock.test","password":"adminpass123"}' | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).token))")

# Same Gateway, two different backends — the JSON body's "service" field
# proves which one actually handled each request.
curl -s localhost:8081/api/v1/reports  -H "Authorization: Bearer $TOKEN"   # -> auth-service
curl -s localhost:8081/api/v1/products -H "Authorization: Bearer $TOKEN"   # -> inventory-service

# No token at all -> rejected by the Gateway itself, never forwarded
curl -s -o /dev/null -w "%{http_code}\n" localhost:8081/api/v1/reports

# Trip the rate limit: 11 requests in under a minute
for i in $(seq 1 11); do
  curl -s -o /dev/null -w "%{http_code}\n" localhost:8081/api/v1/reports -H "Authorization: Bearer $TOKEN"
done
# First 10 print 200, the 11th prints 429
```
