import test from "node:test";
import assert from "node:assert/strict";
import type { SyncMutation } from "@expense-tracker/cloud-sync";
import {
  createDebouncedRunner,
  deriveSyncStatus,
  summarizePendingQueue,
  toSyncStatusLabel,
} from "./syncUx";

test("deriveSyncStatus prefers failed over syncing/pending", () => {
  assert.equal(deriveSyncStatus({ isSyncing: true, pendingCount: 2, lastError: "boom" }), "failed");
  assert.equal(toSyncStatusLabel("pending"), "Pending changes");
});

test("summarizePendingQueue returns grouped counts and oldest timestamp", () => {
  const pending: SyncMutation[] = [
    {
      id: "1",
      entityType: "expense",
      entityId: "e1",
      operation: "create",
      payload: {},
      clientTimestamp: "2026-04-03T01:00:00.000Z",
      version: 1,
    },
    {
      id: "2",
      entityType: "category",
      entityId: "c1",
      operation: "create",
      payload: {},
      clientTimestamp: "2026-04-03T00:30:00.000Z",
      version: 1,
    },
  ];

  const summary = summarizePendingQueue(pending);
  assert.equal(summary.total, 2);
  assert.equal(summary.byEntityType.expense, 1);
  assert.equal(summary.byEntityType.category, 1);
  assert.equal(summary.oldestClientTimestamp, "2026-04-03T00:30:00.000Z");
});

test("createDebouncedRunner coalesces burst calls", async () => {
  let count = 0;
  const debounced = createDebouncedRunner(() => {
    count += 1;
  }, 20);

  debounced.schedule();
  debounced.schedule();
  debounced.schedule();

  await new Promise((resolve) => setTimeout(resolve, 35));
  assert.equal(count, 1);
});
