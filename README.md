# MarketFlow — SmartStock

Supermarket Inventory, Sales Prediction & Payroll Management System.
Course project for CS 4122 (Distributed Systems & Cloud Computing), ICT
University Yaoundé — Group 2.

The full software design document (use cases, class diagram, sequence
diagrams, etc.) is in [`documentation/`](documentation/main.pdf).

## Repository layout

```
services/
  auth-service/   Week 1: registration, login, JWT, role-based access
documentation/    Software Design Document (LaTeX + PDF)
BRANCHING.md      Branch naming convention
docker-compose.yml
```

## Getting started

```
docker compose up --build
```

Starts the auth service on `http://localhost:3000`. See
[`services/auth-service/README.md`](services/auth-service/README.md) for
endpoints and a demo script.

The React frontend lives in a separate repo (`marketflow_frontend`) with its
own `docker-compose.yml` — run this backend first, then `docker compose up
--build` there to get the webapp on `http://localhost:5173`. See that repo's
README for details.

## Contributing

See [`BRANCHING.md`](BRANCHING.md) for the branch naming rule. Branch off
`main`, open a pull request, get it reviewed, merge.
