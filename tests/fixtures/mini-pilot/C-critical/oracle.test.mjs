import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { ReservationLedger } from "./starter/src/reservation-ledger.mjs";

function ledger() {
  const dir = mkdtempSync(join(tmpdir(), "reservation-ledger-"));
  return { dir, path: join(dir, "ledger.json"), store: new ReservationLedger(join(dir, "ledger.json")) };
}

function code(expected) {
  return (error) => error instanceof Error && error.code === expected;
}

test("reservation and settlement are durable and idempotent", () => {
  const { path, store } = ledger();
  const reserved = { id: "r1", owner: "w1", amount: 5, used: 0, status: "reserved" };
  assert.deepEqual(store.reserve({ id: "r1", owner: "w1", amount: 5 }), reserved);
  const reserveCopy = store.reserve({ id: "r1", owner: "w1", amount: 5 });
  assert.deepEqual(reserveCopy, reserved);
  reserveCopy.used = 99;
  assert.deepEqual(store.get("r1"), reserved);
  JSON.parse(readFileSync(path, "utf8"));
  assert.throws(() => store.reserve({ id: "r1", owner: "w2", amount: 5 }), code("RESERVATION_CONFLICT"));
  assert.throws(() => store.reserve({ id: "r1", owner: "w1", amount: 6 }), code("RESERVATION_CONFLICT"));
  const settled = { id: "r1", owner: "w1", amount: 5, used: 3, status: "settled" };
  assert.deepEqual(store.settle("r1", 3), settled);
  const settleCopy = store.settle("r1", 3);
  assert.deepEqual(settleCopy, settled);
  settleCopy.used = 99;
  assert.deepEqual(store.get("r1"), settled);
  assert.deepEqual(store.reserve({ id: "r1", owner: "w1", amount: 5 }), settled);
  assert.throws(() => store.settle("r1", 2), code("RESERVATION_CONFLICT"));
  assert.throws(() => store.settle("missing", 0), code("RESERVATION_NOT_FOUND"));
  assert.deepEqual(new ReservationLedger(path).get("r1"), { id: "r1", owner: "w1", amount: 5, used: 3, status: "settled" });
  JSON.parse(readFileSync(path, "utf8"));
  const copy = store.get("r1");
  copy.used = 99;
  assert.equal(store.get("r1").used, 3);
  assert.equal(store.get("missing"), undefined);
});

test("recovery releases only proven orphans and is idempotent", () => {
  const { path, store } = ledger();
  store.reserve({ id: "live", owner: "worker-live", amount: 4 });
  store.reserve({ id: "orphan", owner: "worker-gone", amount: 7 });
  store.reserve({ id: "settled", owner: "worker-old", amount: 2 });
  store.settle("settled", 2);
  assert.equal(store.recoverOrphans(new Set(["worker-live"])), 1);
  assert.equal(store.recoverOrphans(new Set(["worker-live"])), 0);
  assert.deepEqual(store.get("live"), { id: "live", owner: "worker-live", amount: 4, used: 0, status: "reserved" });
  assert.deepEqual(store.get("orphan"), { id: "orphan", owner: "worker-gone", amount: 7, used: 0, status: "released" });
  assert.deepEqual(store.get("settled"), { id: "settled", owner: "worker-old", amount: 2, used: 2, status: "settled" });
  assert.throws(() => store.settle("orphan", 1), code("RESERVATION_RELEASED"));
  assert.equal(store.reserve({ id: "orphan", owner: "worker-gone", amount: 7 }).status, "released");
  assert.equal(new ReservationLedger(path).get("orphan").status, "released");
  JSON.parse(readFileSync(path, "utf8"));
});

test("validates values and detects corrupt persistence", () => {
  const { dir, path, store } = ledger();
  for (const input of [{ id: "", owner: "w", amount: 1 }, { id: 1, owner: "w", amount: 1 }, { id: "r", owner: "", amount: 1 }, { id: "r", owner: 1, amount: 1 }, { id: "r", owner: "w", amount: 0 }, { id: "r", owner: "w", amount: -1 }, { id: "r", owner: "w", amount: Infinity }]) {
    assert.throws(() => store.reserve(input), TypeError);
  }
  store.reserve({ id: "r", owner: "w", amount: 1 });
  for (const args of [["", 0], [1, 0], ["r", -1], ["r", 2], ["r", NaN], ["r", Infinity]]) {
    assert.throws(() => store.settle(...args), TypeError);
  }
  assert.throws(() => store.recoverOrphans(["w"]), TypeError);
  assert.throws(() => store.recoverOrphans(new Set([""])), TypeError);
  assert.throws(() => store.recoverOrphans(new Set([1])), TypeError);
  assert.throws(() => store.get(""), TypeError);
  writeFileSync(path, "not-json");
  assert.throws(() => new ReservationLedger(path), code("LEDGER_CORRUPT"));
  void dir;
});

test("starter declares no external dependencies", () => {
  const packageJson = JSON.parse(readFileSync(new URL("./starter/package.json", import.meta.url), "utf8"));
  assert.equal(packageJson.dependencies, undefined);
  assert.equal(packageJson.devDependencies, undefined);
});
