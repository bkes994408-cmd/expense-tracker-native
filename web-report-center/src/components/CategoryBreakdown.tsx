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
      {categories.length === 0 ? (
        <p style={{ color: "#666" }}>此月份尚無支出資料</p>
      ) : (
        <ul style={{ margin: 0, paddingLeft: 18 }}>
          {categories.map((entry) => (
            <li key={entry.category} style={{ marginBottom: 6 }}>
              {entry.category}: {entry.amount.toLocaleString()} ({(entry.ratio * 100).toFixed(1)}%)
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
