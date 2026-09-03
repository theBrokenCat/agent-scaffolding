import assert from "node:assert/strict";
import test from "node:test";
import { normalizeHeaderName } from "./starter/src/header-name.mjs";

test("normalizes valid HTTP token names", () => {
  assert.equal(normalizeHeaderName("  X-Request_ID\t"), "x-request_id");
  assert.equal(normalizeHeaderName("!#$%&'*+-.^_`|~"), "!#$%&'*+-.^_`|~");
});

test("rejects invalid types, empty values and separators", () => {
  assert.throws(() => normalizeHeaderName(42), TypeError);
  assert.throws(() => normalizeHeaderName(""), RangeError);
  assert.throws(() => normalizeHeaderName(" \t "), RangeError);
  for (const value of ["two words", "x:y", "x/y", "x\ny", "café", "\u00a0x\u00a0"]) {
    assert.throws(() => normalizeHeaderName(value), TypeError);
  }
});
