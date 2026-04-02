import { useMemo, useState } from "react";
import { summarize, toCsv, type ExpenseRecord, type ReportFilter } from "./lib/report";

const seed: ExpenseRecord[] = [
  { id: "1", title: "薪資", category: "收入", amount: 86000, type: "income", createdAt: "2026-03-01" },
  { id: "2", title: "房租", category: "居住", amount: 21000, type: "expense", createdAt: "2026-03-03" },
  { id: "3", title: "晚餐", category: "飲食", amount: 300, type: "expense", createdAt: "2026-03-05" },
];

export function ReportCenterApp() {
  const [isPro, setIsPro] = useState(false);
  const [filter, setFilter] = useState<ReportFilter>("all");
  const summary = useMemo(() => summarize(seed, filter), [filter]);

  function downloadCsv() {
    const blob = new Blob([toCsv(seed)], { type: "text/csv;charset=utf-8" });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = "report-center-export.csv";
    link.click();
    URL.revokeObjectURL(link.href);
  }

  return (
    <main className="container">
      <h1>Web 報表中心</h1>
      <p>Iteration-7：跨平台報表檢視與匯出</p>
      <div className="row">
        <label>
          <input type="checkbox" checked={isPro} onChange={(e) => setIsPro(e.target.checked)} /> Pro 用戶
        </label>
        <select value={filter} onChange={(e) => setFilter(e.target.value as ReportFilter)}>
          <option value="all">全部</option>
          <option value="income">僅收入</option>
          <option value="expense">僅支出</option>
          <option value="net">僅淨額</option>
        </select>
        <button onClick={downloadCsv}>匯出 CSV</button>
      </div>

      <section className="card">
        <h2>月總覽</h2>
        <ul>
          <li>收入：{summary.income}</li>
          <li>支出：{summary.expense}</li>
          <li>淨額：{summary.net}</li>
          <li>筆數：{summary.count}</li>
        </ul>
      </section>

      <section className="card">
        <h2>進階報表（Pro）</h2>
        {isPro ? <p>✅ 已開通：可顯示趨勢圖、分類比較與 PDF 匯出入口。</p> : <p>🔒 Free 方案僅開放月總覽，升級 Pro 以查看進階分析。</p>}
      </section>
    </main>
  );
}
