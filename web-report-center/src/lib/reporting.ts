import type { ExpenseRecord } from "../types/expense";

export interface MonthlySummary {
  income: number;
  expense: number;
  net: number;
}

export function summarizeMonthly(records: ExpenseRecord[]): MonthlySummary {
  const income = records.filter((r) => r.type === "income").reduce((acc, r) => acc + r.amount, 0);
  const expense = records.filter((r) => r.type === "expense").reduce((acc, r) => acc + r.amount, 0);

  return { income, expense, net: income - expense };
}

export function topCategories(records: ExpenseRecord[]): Array<{ category: string; amount: number }> {
  const bucket = new Map<string, number>();
  for (const r of records.filter((r) => r.type === "expense")) {
    bucket.set(r.category, (bucket.get(r.category) ?? 0) + r.amount);
  }

  return [...bucket.entries()]
    .map(([category, amount]) => ({ category, amount }))
    .sort((a, b) => b.amount - a.amount)
    .slice(0, 5);
}
