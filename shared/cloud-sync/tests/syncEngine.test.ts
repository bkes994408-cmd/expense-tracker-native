import test from "node:test";
import assert from "node:assert/strict";
import { InMemorySyncStateStore } from "../src/store.js";
import { InMemorySyncTransport } from "../src/mockTransport.js";
import { SyncEngine } from "../src/engine.js";

test("SyncEngine should push staged mutations and update cursor", async () => {
  const store = new InMemorySyncStateStore();
  const transport = new InMemorySyncTransport();
  const engine = new SyncEngine("ios-device", store, transport);

  await engine.stageMutation({
    entityType: "expense",
    entityId: "exp-1",
    operation: "create",
    payload: { title: "Lunch", amount: 250 },
    version: 1,
  });

  const result = await engine.syncNow();
  assert.equal(result.pushed, 1);
  assert.equal(result.cursor.deviceId, "ios-device");
  assert.ok(result.cursor.serverCursor);

  const pending = await store.listPendingMutations("ios-device");
  assert.equal(pending.length, 0);
});
