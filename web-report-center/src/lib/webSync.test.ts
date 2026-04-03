import test from "node:test";
import assert from "node:assert/strict";
import {
  InMemorySyncStateStore,
  type SyncMutation,
  type SyncPullRequest,
  type SyncPushRequest,
  type SyncTransport,
} from "@expense-tracker/cloud-sync";
import { runSyncOnce } from "./webSync";

class FakeTransport implements SyncTransport {
  constructor(private readonly serverMutations: SyncMutation[]) {}

  async pushMutations(request: SyncPushRequest) {
    for (const mutation of request.mutations) {
      if (!this.serverMutations.some((item) => item.id === mutation.id)) {
        this.serverMutations.push(mutation);
      }
    }
    return {
      acceptedIds: request.mutations.map((m) => m.id),
      nextCursor: request.baseCursor ?? "0",
    };
  }

  async pullMutations(request: SyncPullRequest) {
    const start = Number(request.fromCursor ?? "0");
    return {
      mutations: this.serverMutations.slice(Number.isNaN(start) ? 0 : start),
      nextCursor: `${this.serverMutations.length}`,
    };
  }
}

function baseMutation(id: string): SyncMutation {
  return {
    id,
    entityType: "category",
    entityId: `c-${id}`,
    operation: "create",
    payload: { name: `分類-${id}` },
    clientTimestamp: "2026-04-03T00:00:00.000Z",
    version: 1,
  };
}

test("runSyncOnce pulls server mutations on first load", async () => {
  const store = new InMemorySyncStateStore();
  const transport = new FakeTransport([baseMutation("seed-1"), baseMutation("seed-2")]);

  const result = await runSyncOnce("web", store, transport);

  assert.equal(result.pushed, 0);
  assert.equal(result.pulled, 2);
  assert.equal(result.pulledMutations.length, 2);
  assert.equal(result.cursor.serverCursor, "2");
});

test("runSyncOnce flushes pending and keeps cursor moving", async () => {
  const store = new InMemorySyncStateStore();
  const transport = new FakeTransport([baseMutation("seed")]);

  await store.enqueueMutation({
    id: "web:local-1",
    entityType: "expense",
    entityId: "e1",
    operation: "create",
    payload: { title: "午餐", categoryId: "c-seed", amount: 120, type: "expense", createdAt: "2026-04-03" },
    clientTimestamp: "2026-04-03T01:00:00.000Z",
    version: 1,
  });

  const first = await runSyncOnce("web", store, transport);
  const pending = await store.listPendingMutations("web");

  assert.equal(first.pushed, 1);
  assert.equal(pending.length, 0);
  assert.equal(first.cursor.serverCursor, "2");
});
