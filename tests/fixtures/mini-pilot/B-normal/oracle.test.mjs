import assert from "node:assert/strict";
import test from "node:test";
import { cappedExponentialDelay } from "./starter/src/backoff.mjs";
import { evaluateRetry } from "./starter/src/retry-policy.mjs";

test("caps exponential delay and validates inputs", () => {
  assert.equal(cappedExponentialDelay(100, 0, 1_000), 100);
  assert.equal(cappedExponentialDelay(100, 4, 1_000), 1_000);
  assert.equal(cappedExponentialDelay(Number.MAX_VALUE, 4, 5_000), 5_000);
  assert.equal(cappedExponentialDelay(0, Number.MAX_SAFE_INTEGER, 5_000), 0);
  for (const args of [[-1, 0, 1], [1, 0.5, 2], [1, 0, Infinity]]) {
    assert.throws(() => cappedExponentialDelay(...args), TypeError);
  }
});

test("evaluates method, status and attempt gates", () => {
  const policy = { baseDelayMs: 100, maxDelayMs: 1_000, allowPost: false };
  assert.deepEqual(evaluateRetry({ method: "PATCH", status: 503, attempt: 0, maxAttempts: 3 }, policy), { retry: false, delayMs: 0, reason: "method" });
  assert.deepEqual(evaluateRetry({ method: "GET", status: 404, attempt: 0, maxAttempts: 3 }, policy), { retry: false, delayMs: 0, reason: "status" });
  assert.deepEqual(evaluateRetry({ method: "GET", status: 503, attempt: 3, maxAttempts: 3 }, policy), { retry: false, delayMs: 0, reason: "exhausted" });
  assert.deepEqual(evaluateRetry({ method: "PATCH", status: 404, attempt: 9, maxAttempts: 3 }, policy), { retry: false, delayMs: 0, reason: "method" });
  for (const method of ["GET", "head", "Put", "delete"]) {
    assert.equal(evaluateRetry({ method, status: 503, attempt: 0, maxAttempts: 1 }, policy).retry, true);
  }
  assert.deepEqual(evaluateRetry({ method: "POST", status: 503, attempt: 0, maxAttempts: 1 }, policy), { retry: false, delayMs: 0, reason: "method" });
  for (const status of [408, 429, 500, 502, 503, 504]) {
    assert.equal(evaluateRetry({ method: "GET", status, attempt: 0, maxAttempts: 1 }, policy).retry, true);
  }
});

test("computes retry delay without mutating inputs", () => {
  const input = { method: "get", status: 503, attempt: 2, maxAttempts: 3 };
  const policy = { baseDelayMs: 100, maxDelayMs: 1_000, allowPost: false };
  assert.deepEqual(evaluateRetry(input, policy), { retry: true, delayMs: 400, reason: "retry" });
  assert.deepEqual(input, { method: "get", status: 503, attempt: 2, maxAttempts: 3 });
  assert.deepEqual(policy, { baseDelayMs: 100, maxDelayMs: 1_000, allowPost: false });
  assert.deepEqual(evaluateRetry({ ...input, retryAfterMs: 5_000 }, policy), { retry: true, delayMs: 1_000, reason: "retry" });
  assert.deepEqual(evaluateRetry({ ...input, method: "POST" }, { ...policy, allowPost: true }), { retry: true, delayMs: 400, reason: "retry" });
});

test("rejects malformed retry inputs", () => {
  const goodInput = { method: "GET", status: 503, attempt: 0, maxAttempts: 1 };
  const goodPolicy = { baseDelayMs: 100, maxDelayMs: 1_000, allowPost: false };
  for (const input of [null, { ...goodInput, method: "" }, { ...goodInput, status: 503.5 }, { ...goodInput, attempt: -1 }, { ...goodInput, maxAttempts: 0.5 }, { ...goodInput, retryAfterMs: -1 }]) {
    assert.throws(() => evaluateRetry(input, goodPolicy), TypeError);
  }
  for (const policy of [null, { ...goodPolicy, baseDelayMs: -1 }, { ...goodPolicy, maxDelayMs: Infinity }, { ...goodPolicy, allowPost: "yes" }]) {
    assert.throws(() => evaluateRetry(goodInput, policy), TypeError);
  }
});
