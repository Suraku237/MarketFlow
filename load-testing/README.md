# Load Testing (Week 4, Build Task 11)

k6 script that sends ramping concurrent requests through the API Gateway
and records how fast it responds — plus, since the Gateway rate-limits at
10 requests/minute/IP, this doubles as a live demonstration of that limit
actually protecting the system under load.

## Install k6

```
winget install k6 --source winget
```
(or see https://grafana.com/docs/k6/latest/set-up/install-k6/ for other
platforms). Confirm with `k6 version`.

## Prerequisite

The stack must be running:
```
docker compose up --build
```
from the repo root.

## Run it — safety profile (default)

Uses the Gateway's normal rate limit (10 req/min). Ramps to 20 virtual
users, so it *will* trip the limiter — this is the point: it proves the
"send enough requests to trigger the rate limit" story under realistic
concurrent load, not just a manual `for` loop of sequential curls.

```
k6 run load-testing/k6/gateway-load-test.js
```

In the summary output at the end, look at:
- `rate_limited_responses` — a custom counter tallying every `429` seen.
  Non-zero confirms the limiter engaged under load.
- `http_req_duration` — response times *including* the fast `429`s, so this
  number understates true "working" latency under this profile. Use the
  speed profile below for a clean latency reading.

## Run it — speed profile (optional)

Temporarily raises the rate limit so the same load test measures genuine
throughput/latency instead of mostly hitting `429`s:

```bash
# 1. Raise the limit and restart just the Gateway with it
RATE_LIMIT_MAX=100000 docker compose up -d gateway

# 2. Run the same test
k6 run load-testing/k6/gateway-load-test.js

# 3. Restore the default limit afterward
docker compose up -d gateway
```

Now `rate_limited_responses` should stay at (or near) `0`, and
`http_req_duration`'s `p(95)` reflects real backend latency under 20
concurrent users.

## Interpreting results for the write-up

Report both profiles: the safety profile shows the rate limiter engaging
(protects against abuse/DoS-style request floods); the speed profile shows
the system's actual response time under load once that's not a factor. The
`thresholds` block in the script (`p(95)<500`ms) gives k6 a pass/fail
verdict printed at the end of the run.
