import type { ExpenseRecord } from "../types/expense";

export const sampleRecords: ExpenseRecord[] = [
  { id: "1", title: "Salary", category: "Income", amount: 70000, type: "income", createdAt: "2026-03-01" },
  { id: "2", title: "Rent", category: "Housing", amount: 18000, type: "expense", createdAt: "2026-03-02" },
  { id: "3", title: "Groceries", category: "Food", amount: 6000, type: "expense", createdAt: "2026-03-05" },
  { id: "4", title: "Transport", category: "Commute", amount: 2200, type: "expense", createdAt: "2026-03-07" }
];
