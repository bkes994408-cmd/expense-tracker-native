import type { ExpenseRecord } from "../types/expense";

export const sampleRecords: ExpenseRecord[] = [
  { id: "1", title: "Salary", category: "Income", amount: 70000, type: "income", createdAt: "2026-03-01" },
  { id: "2", title: "Rent", category: "Housing", amount: 18000, type: "expense", createdAt: "2026-03-02" },
  { id: "3", title: "Groceries", category: "Food", amount: 6000, type: "expense", createdAt: "2026-03-05" },
  { id: "4", title: "Transport", category: "Commute", amount: 2200, type: "expense", createdAt: "2026-03-07" },
  { id: "5", title: "Freelance", category: "Income", amount: 24000, type: "income", createdAt: "2026-02-03" },
  { id: "6", title: "Utilities", category: "Housing", amount: 3900, type: "expense", createdAt: "2026-02-09" },
  { id: "7", title: "Health Insurance", category: "Insurance", amount: 2800, type: "expense", createdAt: "2026-02-14" },
  { id: "8", title: "Dining", category: "Food", amount: 5100, type: "expense", createdAt: "2026-02-17" },
  { id: "9", title: "Streaming", category: "Subscription", amount: 450, type: "expense", createdAt: "2026-02-24" }
];
