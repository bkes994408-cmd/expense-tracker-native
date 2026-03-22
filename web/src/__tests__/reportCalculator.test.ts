import { describe, expect, it } from 'vitest'
import { sampleEntries } from '../data/sampleEntries'
import { aggregateByMonth, filterByPeriod, mapForFilter, summarize } from '../lib/reportCalculator'

describe('reportCalculator', () => {
  it('filters to the latest 1 month', () => {
    const items = filterByPeriod(sampleEntries, 1)
    expect(items.every((item) => item.createdAt.startsWith('2026-03'))).toBe(true)
  })

  it('builds monthly buckets and net values', () => {
    const monthly = aggregateByMonth(filterByPeriod(sampleEntries, 3))
    expect(monthly).toHaveLength(3)
    const latest = monthly[monthly.length - 1]
    expect(latest?.month).toBe('2026-03')
    expect(latest?.net).toBeGreaterThan(0)
  })

  it('maps expense filter into positive values for chart readability', () => {
    const monthly = aggregateByMonth(filterByPeriod(sampleEntries, 3))
    const mapped = mapForFilter(monthly, 'expense')
    expect(mapped.every((item) => item.value >= 0)).toBe(true)
  })

  it('summarizes income/expense/net', () => {
    const summary = summarize(filterByPeriod(sampleEntries, 3))
    expect(summary.income).toBe(80500)
    expect(summary.expense).toBe(28800)
    expect(summary.net).toBe(51700)
  })
})
