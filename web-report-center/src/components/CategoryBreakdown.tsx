import type { ExpenseRecord } from "../types/expense";
import { topCategories } from "../lib/reporting";

interface Props {
  records: ExpenseRecord[];
}

export function CategoryBreakdown({ records }: Props) {
  const categories = topCategories(records);

  return (
    <section style={{ marginTop: 16 }}>
      <h3>支出分類 Top 5</h3>
      <ul>
        {categories.map((entry) => (
          <li key={entry.category}>
            {entry.category}: {entry.amount.toLocaleString()}
          </li>
        ))}
      </ul>
    </section>
  );
}
