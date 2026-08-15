# SmartSchool Finance Service

Invoices module (Week 4). Not reachable directly — only through the
[API Gateway](../gateway/README.md) at `/api/v1/finance/invoices`.

This service does two things:
1. Serves `GET /api/invoices` (an ordinary HTTP endpoint).
2. **Consumes** the `enrollment.created` event that `academic-service`
   publishes to RabbitMQ, and creates an invoice for each one — the Week 4
   asynchronous workflow. Nothing calls this service directly to create an
   invoice; it reacts to a message on its own schedule.

## The asynchronous workflow (for the oral evaluation)

**The event**: when `POST /api/v1/enrollments` succeeds in `academic-service`
(see [`../academic-service/src/routes/enrollments.routes.js`](../academic-service/src/routes/enrollments.routes.js)),
it publishes a message to a RabbitMQ **direct exchange** `school_events`
with routing key `enrollment.created`, *after* the enrollment row has
already committed to MySQL. Publishing is wrapped so it can never fail or
delay the HTTP response — see
[`../academic-service/src/events/publisher.js`](../academic-service/src/events/publisher.js).

**What's inside the message** — flat and easy to explain live:
```json
{
  "eventId": "3f9c2e2a-...",
  "eventType": "enrollment.created",
  "occurredAt": "2026-08-15T10:00:00.000Z",
  "data": {
    "enrollmentId": 5,
    "studentId": 3,
    "studentName": "Ama Nti",
    "studentEmail": "ama@smartschool.local",
    "courseId": 3,
    "courseCode": "SCI101",
    "courseName": "Introduction to Science",
    "feeAmount": "30000.00",
    "term": "2026-S2"
  }
}
```
`studentId` is the `students.id` (not the login `users.id`), so this service
can insert straight into `invoices.student_id` with no extra lookup.

**The consumer**: [`src/events/consumer.js`](src/events/consumer.js)
connects to RabbitMQ independently (its own retry-with-backoff on startup,
since the healthcheck passing doesn't guarantee AMQP is instantly ready),
declares the same exchange/queue/binding, and processes messages with a
manual ack: on success it inserts an `invoices` row and acks; if that
invoice already exists (RabbitMQ's at-least-once delivery redelivered the
same event), it acks anyway rather than erroring, since the outcome is the
same either way; on any other error it nacks once for a single redelivery
attempt, then drops the message rather than retrying forever.

**Why this is genuinely "Service A doesn't wait for Service B"**: stop this
container, then create an enrollment — `POST /api/v1/enrollments` still
returns `201` immediately. The message sits durably queued in RabbitMQ.
Start this container again and it drains the backlog and creates the
invoice, with no retry or resend needed from academic-service.

## Live proof for the evaluation

- `GET /api/v1/finance/invoices` through the Gateway (or the frontend's "My
  invoices" panel) — the new invoice appears once the consumer processes it.
- This service's own logs (`docker compose logs -f finance-service`) print a
  line for every message received and every invoice created.
- RabbitMQ's management UI at `http://localhost:15672` (user/pass `guest`/
  `guest`, the image's default) — the `school_events` exchange and
  `invoice_creation_queue` queue show live message/ack counts.

## Endpoints

| Method | Path            | Auth        | Description |
|--------|-----------------|-------------|--------------|
| GET    | `/health`       | none        | Liveness check |
| GET    | `/api/invoices` | Bearer JWT  | List invoices — a `student` only ever sees their own; `admin`/`teacher` see all, or filter with `?studentId=` |

## Run it

Brought up as part of the full stack:
```
docker compose up --build
```
from the repo root. Not published to the host on its own — reach it via
`http://localhost:8081/api/v1/finance/invoices` (through the Gateway).

To run it standalone against a local MySQL + RabbitMQ for development:
```
npm install
cp .env.example .env
npm start
```
