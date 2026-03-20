export type ReportFilter = "all" | "income" | "expense" | "net";

export interface ExpenseRecord {
  id: string;
  title: string;
  category: string;
  amount: number;
  type: "income" | "expense";
  createdAt: string;
}

export function summarize(records: ExpenseRecord[], filter: ReportFilter) {
  const filtered = records.filter((record) => filter === "all" || record.type === filter || filter === "net");
  const income = filtered.filter((r) => r.type === "income").reduce((sum, r) => sum + r.amount, 0);
  const expense = filtered.filter((r) => r.type === "expense").reduce((sum, r) => sum + r.amount, 0);
  return { income, expense, net: income - expense, count: filtered.length };
}

export function toCsv(records: ExpenseRecord[]): string {
  const header = "id,title,category,type,amount,createdAt";
  const lines = records.map((r) => [r.id, r.title, r.category, r.type, r.amount.toString(), r.createdAt].join(","));
  return [header, ...lines].join("\n");
}
