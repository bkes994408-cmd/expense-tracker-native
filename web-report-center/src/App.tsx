import { useMemo, useState } from "react";
import { ReportCards } from "./components/ReportCards";
import { CategoryBreakdown } from "./components/CategoryBreakdown";
import { extractMonths, filterByMonth, summarizeMonthly } from "./lib/reporting";
import { sampleRecords } from "./features/sampleData";
import { deriveCategories, runSyncSmoke } from "./features/syncSmoke";

export function App() {
  const [records, setRecords] = useState(sampleRecords);
  const [categories, setCategories] = useState(() => deriveCategories(sampleRecords));
  const [syncStatus, setSyncStatus] = useState("尚未執行同步");

  const months = useMemo(() => extractMonths(records), [records]);
  const [selectedMonth, setSelectedMonth] = useState<string>(months[0] ?? "");
  const scopedRecords = useMemo(() => filterByMonth(records, selectedMonth), [records, selectedMonth]);
  const summary = useMemo(() => summarizeMonthly(scopedRecords), [scopedRecords]);

  const handleSyncSmoke = async () => {
    setSyncStatus("同步中...");
    try {
      const result = await runSyncSmoke({ expenses: records, categories }, (next) => {
        setRecords(next.expenses);
        setCategories(next.categories);
      });
      setSyncStatus(`同步完成：pushed ${result.pushed}，patched ${result.patched}，pending=${result.hasPending}`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      setSyncStatus(`同步失敗：${message}`);
    }
  };

  return (
    <main style={{ maxWidth: 920, margin: "32px auto", fontFamily: "sans-serif", padding: "0 12px" }}>
      <h1>Web 報表中心</h1>
      <p>Iteration-7：跨裝置擴展（Web）</p>

      <div style={{ display: "flex", gap: 12, alignItems: "end", flexWrap: "wrap", marginBottom: 16 }}>
        <label style={{ display: "inline-grid", gap: 6 }}>
          <span style={{ fontSize: 14, color: "#666" }}>月份</span>
          <select value={selectedMonth} onChange={(e) => setSelectedMonth(e.target.value)}>
            {months.map((month) => (
              <option key={month} value={month}>
                {month}
              </option>
            ))}
          </select>
        </label>

        <button onClick={handleSyncSmoke}>執行雲端同步 Smoke（expenses/categories）</button>
      </div>

      <p style={{ marginTop: 0, color: "#444" }}>{syncStatus}</p>

      <ReportCards summary={summary} />
      <CategoryBreakdown records={scopedRecords} />
    </main>
  );
}
