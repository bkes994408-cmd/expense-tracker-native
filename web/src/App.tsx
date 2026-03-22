import { useMemo, useState } from 'react'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis
} from 'recharts'
import { sampleEntries } from './data/sampleEntries'
import { aggregateByMonth, filterByPeriod, mapForFilter, summarize } from './lib/reportCalculator'
import type { PeriodOption, ReportFilter } from './types'

type ChartMode = 'line' | 'bar'

const periodOptions: PeriodOption[] = [1, 3, 6, 12]
const filterOptions: ReportFilter[] = ['all', 'income', 'expense', 'net']

const currency = (value: number) =>
  new Intl.NumberFormat('zh-TW', { style: 'currency', currency: 'TWD', maximumFractionDigits: 0 }).format(value)

export const App = () => {
  const [period, setPeriod] = useState<PeriodOption>(3)
  const [filter, setFilter] = useState<ReportFilter>('all')
  const [mode, setMode] = useState<ChartMode>('line')

  const periodEntries = useMemo(() => filterByPeriod(sampleEntries, period), [period])
  const summary = useMemo(() => summarize(periodEntries), [periodEntries])
  const chartData = useMemo(() => mapForFilter(aggregateByMonth(periodEntries), filter), [periodEntries, filter])

  return (
    <main className="layout">
      <header>
        <h1>Web 報表中心（MVP）</h1>
        <p>大螢幕檢視跨月份收支趨勢，與 iOS/Android 的進階報表篩選邏輯對齊。</p>
      </header>

      <section className="toolbar" aria-label="report controls">
        <div>
          <label htmlFor="period">區間</label>
          <select id="period" value={period} onChange={(e) => setPeriod(Number(e.target.value) as PeriodOption)}>
            {periodOptions.map((value) => (
              <option key={value} value={value}>{`${value}M`}</option>
            ))}
          </select>
        </div>

        <div>
          <label htmlFor="filter">資料篩選</label>
          <select id="filter" value={filter} onChange={(e) => setFilter(e.target.value as ReportFilter)}>
            {filterOptions.map((value) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label htmlFor="mode">圖表</label>
          <select id="mode" value={mode} onChange={(e) => setMode(e.target.value as ChartMode)}>
            <option value="line">line</option>
            <option value="bar">bar</option>
          </select>
        </div>
      </section>

      <section className="summary-grid" aria-label="summary cards">
        <article>
          <h2>收入</h2>
          <p>{currency(summary.income)}</p>
        </article>
        <article>
          <h2>支出</h2>
          <p>{currency(summary.expense)}</p>
        </article>
        <article>
          <h2>淨額</h2>
          <p>{currency(summary.net)}</p>
        </article>
      </section>

      <section className="chart-panel" aria-label="chart panel">
        <h2>趨勢圖</h2>
        <ResponsiveContainer width="100%" height={360}>
          {mode === 'line' ? (
            <LineChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip formatter={(value: number) => currency(value)} />
              <Line type="monotone" dataKey="value" stroke="#2563eb" strokeWidth={3} />
            </LineChart>
          ) : (
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis />
              <Tooltip formatter={(value: number) => currency(value)} />
              <Bar dataKey="value" fill="#0ea5e9" radius={[8, 8, 0, 0]} />
            </BarChart>
          )}
        </ResponsiveContainer>
      </section>
    </main>
  )
}
