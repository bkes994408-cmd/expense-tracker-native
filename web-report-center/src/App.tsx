import { useMemo, useState } from "react";
import { ReportCards } from "./components/ReportCards";
import { CategoryBreakdown } from "./components/CategoryBreakdown";
import { extractMonths, filterByMonth, summarizeMonthly } from "./lib/reporting";
import { sampleRecords } from "./features/sampleData";

export function App() {
  const months = useMemo(() => extractMonths(sampleRecords), []);
  const [selectedMonth, setSelectedMonth] = useState<string>(months[0] ?? "");
  const scopedRecords = useMemo(() => filterByMonth(sampleRecords, selectedMonth), [selectedMonth]);
  const summary = useMemo(() => summarizeMonthly(scopedRecords), [scopedRecords]);

  return (
    <main style={{ maxWidth: 920, margin: "32px auto", fontFamily: "sans-serif", padding: "0 12px" }}>
      <h1>Web 報表中心</h1>
      <p>Iteration-7：跨裝置擴展（Web）</p>

      <label style={{ display: "inline-grid", gap: 6, marginBottom: 16 }}>
        <span style={{ fontSize: 14, color: "#666" }}>月份</span>
        <select value={selectedMonth} onChange={(e) => setSelectedMonth(e.target.value)}>
          {months.map((month) => (
            <option key={month} value={month}>
              {month}
            </option>
          ))}
        </select>
      </label>

      <ReportCards summary={summary} />
      <CategoryBreakdown records={scopedRecords} />
    </main>
  );
}
