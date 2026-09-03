import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync } from "node:fs";
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
  assert.equal(store.reserve({ id: "r1", owner: "w1", amount: 5 }).status, "reserved");
  assert.equal(store.reserve({ id: "r1", owner: "w1", amount: 5 }).status, "reserved");
  assert.throws(() => store.reserve({ id: "r1", owner: "w2", amount: 5 }), code("RESERVATION_CONFLICT"));
  assert.throws(() => store.reserve({ id: "r1", owner: "w1", amount: 6 }), code("RESERVATION_CONFLICT"));
  assert.equal(store.settle("r1", 3).used, 3);
  assert.equal(store.settle("r1", 3).used, 3);
  assert.equal(store.reserve({ id: "r1", owner: "w1", amount: 5 }).status, "settled");
  assert.throws(() => store.settle("r1", 2), code("RESERVATION_CONFLICT"));
  assert.throws(() => store.settle("missing", 0), code("RESERVATION_NOT_FOUND"));
  assert.deepEqual(new ReservationLedger(path).get("r1"), { id: "r1", owner: "w1", amount: 5, used: 3, status: "settled" });
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
  assert.equal(store.get("live").status, "reserved");
  assert.equal(store.get("orphan").status, "released");
  assert.equal(store.get("orphan").used, 0);
  assert.equal(store.get("settled").status, "settled");
  assert.throws(() => store.settle("orphan", 1), code("RESERVATION_RELEASED"));
  assert.equal(store.reserve({ id: "orphan", owner: "worker-gone", amount: 7 }).status, "released");
  assert.equal(new ReservationLedger(path).get("orphan").status, "released");
});

test("validates values and detects corrupt persistence", () => {
  const { dir, path, store } = ledger();
  assert.throws(() => store.reserve({ id: "", owner: "w", amount: 1 }));
  assert.throws(() => store.reserve({ id: "r", owner: "", amount: 1 }));
  assert.throws(() => store.reserve({ id: "r", owner: "w", amount: 0 }));
  store.reserve({ id: "r", owner: "w", amount: 1 });
  assert.throws(() => store.settle("r", 2));
  assert.throws(() => store.recoverOrphans(["w"]), TypeError);
  assert.throws(() => store.recoverOrphans(new Set([""])), TypeError);
  assert.throws(() => store.get(""), TypeError);
  writeFileSync(path, "not-json");
  assert.throws(() => new ReservationLedger(path), code("LEDGER_CORRUPT"));
  void dir;
});
