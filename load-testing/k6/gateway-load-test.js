// k6 load test against the SmartSchool API Gateway (Week 4, Build Task 11).
//
// Logs in once in setup() and reuses the same JWT across every virtual
// user, so the ramping load itself only ever hits one endpoint
// (GET /api/v1/courses) — this keeps the "how fast" measurement clean and
// avoids the login rate limit being what gets hit instead of the one
// under test.
//
// Usage: see ../README.md for the two run profiles (default "safety" vs
// "speed").

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8081/api/v1';
const EMAIL = __ENV.LOAD_TEST_EMAIL || 'loadtest@smartschool.test';
const PASSWORD = __ENV.LOAD_TEST_PASSWORD || 'loadtestpass123';

export const rateLimited = new Counter('rate_limited_responses');

export const options = {
  stages: [
    { duration: '30s', target: 20 }, // ramp up
    { duration: '1m', target: 20 },  // hold
    { duration: '15s', target: 0 },  // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
  },
};

export function setup() {
  const headers = { headers: { 'Content-Type': 'application/json' } };

  // Register is allowed to fail (409) on repeat runs — the account already
  // existing from a previous run is fine, we just need it to exist once.
  http.post(
    `${BASE_URL}/auth/register`,
    JSON.stringify({ name: 'Load Test', email: EMAIL, password: PASSWORD, role: 'student' }),
    headers
  );

  const loginRes = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({ email: EMAIL, password: PASSWORD }),
    headers
  );

  const token = loginRes.json('token');
  if (!token) {
    throw new Error(`setup() could not log in: ${loginRes.status} ${loginRes.body}`);
  }
  return { token };
}

export default function (data) {
  const res = http.get(`${BASE_URL}/courses`, {
    headers: { Authorization: `Bearer ${data.token}` },
  });

  if (res.status === 429) {
    rateLimited.add(1);
  }

  check(res, {
    'status is 200 or 429': (r) => r.status === 200 || r.status === 429,
  });

  sleep(1);
}
