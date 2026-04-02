import { describe, expect, it } from "vitest";
import { applyIncomingPatches, type SyncState } from "./syncSmoke";

describe("syncSmoke applyIncomingPatches", () => {
  it("應套用較新的 expense/category patch", () => {
    const state: SyncState = {
      expenses: [
        {
          id: "e1",
          title: "Lunch",
          amount: 120,
          type: "expense",
          category: "Food",
          createdAt: "2026-03-01T12:00:00.000Z"
        }
      ],
      categories: [
        {
          id: "cat-food",
          name: "Food",
          updatedAt: "2026-03-01T12:00:00.000Z"
        }
      ]
    };

    const next = applyIncomingPatches(state, [
      {
        id: "m-category",
        entity: "category",
        entityId: "cat-food",
        type: "update",
        payload: JSON.stringify({ id: "cat-food", name: "Meals", updatedAt: "2026-03-01T13:00:00.000Z" }),
        updatedAt: "2026-03-01T13:00:00.000Z"
      },
      {
        id: "m-expense",
        entity: "expense",
        entityId: "e1",
        type: "update",
        payload: JSON.stringify({
          id: "e1",
          title: "Lunch + Coffee",
          amount: 180,
          type: "expense",
          categoryId: "cat-food",
          createdAt: "2026-03-01T12:00:00.000Z",
          updatedAt: "2026-03-01T13:00:00.000Z"
        }),
        updatedAt: "2026-03-01T13:00:00.000Z"
      }
    ]);

    expect(next.expenses[0].title).toBe("Lunch + Coffee");
    expect(next.expenses[0].amount).toBe(180);
    expect(next.expenses[0].category).toBe("Meals");
  });
});
