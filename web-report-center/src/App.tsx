import { ReportCards } from "./components/ReportCards";
import { CategoryBreakdown } from "./components/CategoryBreakdown";
import { summarizeMonthly } from "./lib/reporting";
import { sampleRecords } from "./features/sampleData";

export function App() {
  const summary = summarizeMonthly(sampleRecords);

  return (
    <main style={{ maxWidth: 920, margin: "32px auto", fontFamily: "sans-serif" }}>
      <h1>Web 報表中心</h1>
      <p>Iteration-7：跨裝置擴展（Web）</p>
      <ReportCards summary={summary} />
      <CategoryBreakdown records={sampleRecords} />
    </main>
  );
}
