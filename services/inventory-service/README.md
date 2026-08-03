# SmartStock Inventory Service

Product catalog module (Week 3's "one module service" alongside
auth-service). Reads/writes the `products`/`categories` tables from
`database/schema.sql` (Week 2). Not reachable directly — only through the
[API Gateway](../gateway/README.md) at `/api/v1/products`.

## Endpoints (native paths — see the Gateway for the external `/api/v1/...` mapping)

| Method | Path                | Auth                     | Description |
|--------|---------------------|--------------------------|-------------|
| GET    | `/health`           | none                     | Liveness check |
| GET    | `/api/products`     | Bearer JWT               | List all products |
| GET    | `/api/products/:id` | Bearer JWT               | Get one product |
| POST   | `/api/products`     | Bearer JWT, role `admin` | Create a product |

This service independently verifies the JWT (same shared `JWT_SECRET` as
auth-service) rather than trusting the Gateway blindly — the Gateway only
confirms "logged in", so role checks like `POST /api/products` being
Admin-only still happen here, same pattern as `auth-service`'s
`authorize()` middleware.

## Run it

Brought up as part of the full stack:
```
docker compose up --build
```
from the repo root. Not published to the host on its own — reach it via
`http://localhost:8081/api/v1/products` (through the Gateway).

To run it standalone against a local MySQL for development:
```
npm install
cp .env.example .env
npm start
```
