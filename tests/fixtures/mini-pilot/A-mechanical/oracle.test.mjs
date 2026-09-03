import assert from "node:assert/strict";
import test from "node:test";
import { normalizeHeaderName } from "./starter/src/header-name.mjs";

test("normalizes valid HTTP token names", () => {
  assert.equal(normalizeHeaderName("\t X-Request2_ID \t"), "x-request2_id");
  assert.equal(normalizeHeaderName("!#$%&'*+-.^_`|~"), "!#$%&'*+-.^_`|~");
});

test("rejects invalid types, empty values and separators", () => {
  for (const value of [42, null, undefined, true, {}, []]) {
    assert.throws(() => normalizeHeaderName(value), TypeError);
  }
  assert.throws(() => normalizeHeaderName(""), RangeError);
  assert.throws(() => normalizeHeaderName(" \t "), RangeError);
  for (const value of ["two words", "x:y", "x/y", "x\ny", "café", "\u00a0x\u00a0"]) {
    assert.throws(() => normalizeHeaderName(value), TypeError);
  }
});

test("does not depend on call history", () => {
  assert.equal(normalizeHeaderName("X-A"), "x-a");
  assert.throws(() => normalizeHeaderName("bad value"), TypeError);
  assert.equal(normalizeHeaderName("X-A"), "x-a");
  assert.equal(normalizeHeaderName("X-B"), "x-b");
  assert.equal(normalizeHeaderName("X-A"), "x-a");
});
