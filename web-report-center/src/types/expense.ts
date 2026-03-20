export type ExpenseType = "income" | "expense";

export interface ExpenseRecord {
  id: string;
  title: string;
  category: string;
  amount: number;
  type: ExpenseType;
  createdAt: string;
}
