# SmartSchool Academic Service

Academic module: courses, enrollments, grades (Week 3's "one module service"
alongside auth-service). Reads/writes the
`courses`/`students`/`enrollments`/`grades` tables from `database/schema.sql`
(Week 2). Not reachable directly — only through the
[API Gateway](../gateway/README.md) at `/api/v1/{courses,enrollments,grades}`.

## Endpoints (native paths — see the Gateway for the external `/api/v1/...` mapping)

| Method | Path                | Auth                              | Description |
|--------|---------------------|------------------------------------|-------------|
| GET    | `/health`           | none                               | Liveness check |
| GET    | `/api/courses`      | Bearer JWT                         | List all courses |
| GET    | `/api/courses/:id`  | Bearer JWT                         | Get one course |
| POST   | `/api/courses`      | Bearer JWT, role `admin`           | Create a course |
| GET    | `/api/enrollments`  | Bearer JWT                         | List enrollments — a `student` only ever sees their own; `admin`/`teacher` can filter with `?studentId=`/`?courseId=` |
| POST   | `/api/enrollments`  | Bearer JWT, role `admin` or `student` | Enroll — a `student` enrolls themselves; an `admin` enrolls on behalf of a given `studentId`. **This is the Week 4 event trigger** (see `src/events/publisher.js`) |
| GET    | `/api/grades`       | Bearer JWT                         | List grades — `student` sees only their own; `teacher` sees only grades for courses they teach; `admin` sees all |
| POST   | `/api/grades`       | Bearer JWT, role `admin` or `teacher` | Record a grade — a `teacher` may only grade enrollments in courses they teach (403 otherwise) |

This service independently verifies the JWT (same shared `JWT_SECRET` as
auth-service) rather than trusting the Gateway blindly — the Gateway only
confirms "logged in", so role/ownership checks (e.g. a teacher only grading
their own courses) still happen here, same pattern as `auth-service`'s
`authorize()` middleware.

## Run it

Brought up as part of the full stack:
```
docker compose up --build
```
from the repo root. Not published to the host on its own — reach it via
`http://localhost:8081/api/v1/courses` etc. (through the Gateway).

To run it standalone against a local MySQL for development:
```
npm install
cp .env.example .env
npm start
```
