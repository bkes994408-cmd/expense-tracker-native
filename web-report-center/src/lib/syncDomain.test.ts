import test from "node:test";
import assert from "node:assert/strict";
import type { SyncMutation } from "@expense-tracker/cloud-sync";
import { applySyncMutations, type SyncDomainState } from "./syncDomain";

function mutation(overrides: Partial<SyncMutation>): SyncMutation {
  return {
    id: "d:1",
    entityType: "expense",
    entityId: "e1",
    operation: "create",
    payload: { title: "午餐", categoryId: "c1", amount: 120, type: "expense", createdAt: "2026-04-01" },
    clientTimestamp: "2026-04-01T00:00:00.000Z",
    version: 1,
    ...overrides,
  };
}

test("applySyncMutations upserts categories and expenses", () => {
  const initial: SyncDomainState = { categories: [], expenses: [] };
  const next = applySyncMutations(initial, [
    mutation({
      id: "seed:c1",
      entityType: "category",
      entityId: "c1",
      payload: { name: "飲食" },
    }),
    mutation({ id: "seed:e1" }),
    mutation({ id: "seed:e1-update", operation: "update", payload: { title: "晚餐", categoryId: "c1", amount: 180, type: "expense", createdAt: "2026-04-01" } }),
  ]);

  assert.equal(next.categories.length, 1);
  assert.equal(next.categories[0].name, "飲食");
  assert.equal(next.expenses.length, 1);
  assert.equal(next.expenses[0].title, "晚餐");
  assert.equal(next.expenses[0].amount, 180);
});

test("applySyncMutations handles delete", () => {
  const initial: SyncDomainState = {
    categories: [{ id: "c1", name: "飲食" }],
    expenses: [{ id: "e1", title: "午餐", categoryId: "c1", amount: 120, type: "expense", createdAt: "2026-04-01" }],
  };

  const next = applySyncMutations(initial, [
    mutation({ id: "del-expense", operation: "delete", entityType: "expense", entityId: "e1", payload: {} }),
    mutation({ id: "del-category", operation: "delete", entityType: "category", entityId: "c1", payload: {} }),
  ]);

  assert.equal(next.expenses.length, 0);
  assert.equal(next.categories.length, 0);
});
