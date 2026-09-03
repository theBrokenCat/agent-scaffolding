import assert from "node:assert/strict";
import { mkdtempSync, readdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { ReservationLedger } from "./starter/src/reservation-ledger.mjs";

function ledger() {
  const dir = mkdtempSync(join(tmpdir(), "reservation-ledger-"));
  return { dir, path: join(dir, "ledger.json"), store: new ReservationLedger(join(dir, "ledger.json")) };
}

test("reservation and settlement are durable and idempotent", () => {
  const { path, store } = ledger();
  assert.equal(store.reserve({ id: "r1", owner: "w1", amount: 5 }).status, "reserved");
  assert.equal(store.reserve({ id: "r1", owner: "w1", amount: 5 }).status, "reserved");
  assert.throws(() => store.reserve({ id: "r1", owner: "w2", amount: 5 }));
  assert.equal(store.settle("r1", 3).used, 3);
  assert.equal(store.settle("r1", 3).used, 3);
  assert.throws(() => store.settle("r1", 2));
  assert.deepEqual(new ReservationLedger(path).get("r1"), { id: "r1", owner: "w1", amount: 5, used: 3, status: "settled" });
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
  assert.equal(store.get("settled").status, "settled");
  assert.throws(() => store.settle("orphan", 1));
  assert.equal(new ReservationLedger(path).get("orphan").status, "released");
});

test("validates values and leaves no temporary files after successful writes", () => {
  const { dir, store } = ledger();
  assert.throws(() => store.reserve({ id: "", owner: "w", amount: 1 }));
  assert.throws(() => store.reserve({ id: "r", owner: "", amount: 1 }));
  assert.throws(() => store.reserve({ id: "r", owner: "w", amount: 0 }));
  store.reserve({ id: "r", owner: "w", amount: 1 });
  assert.throws(() => store.settle("r", 2));
  assert.deepEqual(readdirSync(dir).filter((name) => name.includes(".tmp")), []);
});

