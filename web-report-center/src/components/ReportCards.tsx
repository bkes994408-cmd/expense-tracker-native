import type { MonthlySummary } from "../lib/reporting";

interface Props {
  summary: MonthlySummary;
}

export function ReportCards({ summary }: Props) {
  return (
    <section style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12 }}>
      <Card label="收入" value={summary.income} />
      <Card label="支出" value={summary.expense} />
      <Card label="淨額" value={summary.net} />
    </section>
  );
}

function Card({ label, value }: { label: string; value: number }) {
  return (
    <div style={{ border: "1px solid #ddd", borderRadius: 8, padding: 16 }}>
      <div style={{ color: "#666", marginBottom: 6 }}>{label}</div>
      <strong>{value.toLocaleString()}</strong>
    </div>
  );
}
