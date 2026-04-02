import test from "node:test";
import assert from "node:assert/strict";
import { applyQuery, summarize, type ExpenseRecord } from "./report";

const records: ExpenseRecord[] = [
  { id: "1", title: "薪資", category: "收入", amount: 100, type: "income", createdAt: "2026-03-01" },
  { id: "2", title: "午餐", category: "飲食", amount: 50, type: "expense", createdAt: "2026-03-02" },
];

test("applyQuery filters by keyword", () => {
  const result = applyQuery(records, { filter: "all", keyword: "午" });
  assert.equal(result.length, 1);
  assert.equal(result[0].id, "2");
});

test("summarize computes income/expense/net", () => {
  const summary = summarize(records);
  assert.deepEqual(summary, { income: 100, expense: 50, net: 50, count: 2 });
});
