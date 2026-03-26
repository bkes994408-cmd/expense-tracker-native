import type { ExpenseRecord } from "../types/expense";

export interface MonthlySummary {
  income: number;
  expense: number;
  net: number;
}

export interface CategorySummary {
  category: string;
  amount: number;
  ratio: number;
}

export function summarizeMonthly(records: ExpenseRecord[]): MonthlySummary {
  const income = records.filter((r) => r.type === "income").reduce((acc, r) => acc + r.amount, 0);
  const expense = records.filter((r) => r.type === "expense").reduce((acc, r) => acc + r.amount, 0);

  return { income, expense, net: income - expense };
}

export function topCategories(records: ExpenseRecord[]): CategorySummary[] {
  const expenseRecords = records.filter((r) => r.type === "expense");
  const totalExpense = expenseRecords.reduce((acc, r) => acc + r.amount, 0);
  const bucket = new Map<string, number>();

  for (const r of expenseRecords) {
    bucket.set(r.category, (bucket.get(r.category) ?? 0) + r.amount);
  }

  return [...bucket.entries()]
    .map(([category, amount]) => ({
      category,
      amount,
      ratio: totalExpense === 0 ? 0 : amount / totalExpense
    }))
    .sort((a, b) => b.amount - a.amount)
    .slice(0, 5);
}

export function filterByMonth(records: ExpenseRecord[], month: string): ExpenseRecord[] {
  if (!month) return [...records];
  return records.filter((record) => record.createdAt.startsWith(month));
}

export function extractMonths(records: ExpenseRecord[]): string[] {
  const months = new Set(records.map((record) => record.createdAt.slice(0, 7)));
  return [...months].sort((a, b) => (a < b ? 1 : -1));
}
