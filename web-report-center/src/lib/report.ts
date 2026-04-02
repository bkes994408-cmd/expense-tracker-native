export type ReportFilter = "all" | "income" | "expense" | "net";

export interface ExpenseRecord {
  id: string;
  title: string;
  category: string;
  amount: number;
  type: "income" | "expense";
  createdAt: string;
}

export interface ReportQuery {
  filter?: ReportFilter;
  keyword?: string;
}

export function applyQuery(records: ExpenseRecord[], query: ReportQuery = {}): ExpenseRecord[] {
  const filter = query.filter ?? "all";
  const keyword = query.keyword?.trim();

  return records.filter((record) => {
    const byType = filter === "all" || filter === "net" || record.type === filter;
    const byKeyword =
      !keyword ||
      record.title.includes(keyword) ||
      record.category.includes(keyword);
    return byType && byKeyword;
  });
}

export function summarize(records: ExpenseRecord[], filter: ReportFilter = "all") {
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
