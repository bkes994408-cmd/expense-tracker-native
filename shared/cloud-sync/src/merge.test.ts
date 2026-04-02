import { describe, expect, it } from "vitest";
import { mergeCategories, mergeExpenses } from "./merge";

describe("merge helpers", () => {
  it("prefers newer incoming expense", () => {
    const local = [
      {
        id: "e1",
        title: "Lunch",
        amount: 120,
        type: "expense" as const,
        categoryId: "c-food",
        createdAt: "2026-03-01T12:00:00.000Z",
        updatedAt: "2026-03-01T12:00:00.000Z"
      }
    ];

    const incoming = [
      {
        id: "e1",
        title: "Lunch with coffee",
        amount: 180,
        type: "expense" as const,
        categoryId: "c-food",
        createdAt: "2026-03-01T12:00:00.000Z",
        updatedAt: "2026-03-01T13:00:00.000Z"
      }
    ];

    const merged = mergeExpenses(local, incoming);
    expect(merged).toHaveLength(1);
    expect(merged[0].amount).toBe(180);
    expect(merged[0].title).toBe("Lunch with coffee");
  });

  it("keeps local category when incoming is older", () => {
    const local = [{ id: "c1", name: "Food", updatedAt: "2026-03-02T00:00:00.000Z", colorHex: "#ff6600" }];
    const incoming = [{ id: "c1", name: "Meals", updatedAt: "2026-03-01T00:00:00.000Z", colorHex: "#222222" }];

    const merged = mergeCategories(local, incoming);
    expect(merged).toHaveLength(1);
    expect(merged[0].name).toBe("Food");
    expect(merged[0].colorHex).toBe("#ff6600");
  });
});
