import type { LedgerEntry, PeriodOption, ReportFilter } from '../types'

export type MonthlyAggregate = {
  month: string
  income: number
  expense: number
  net: number
}

const monthKey = (date: Date): string => `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(2, '0')}`

export const filterByPeriod = (entries: LedgerEntry[], period: PeriodOption): LedgerEntry[] => {
  if (entries.length === 0) return []
  const latestDate = entries
    .map((entry) => new Date(entry.createdAt))
    .reduce((latest, current) => (current > latest ? current : latest))

  const start = new Date(Date.UTC(latestDate.getUTCFullYear(), latestDate.getUTCMonth() - (period - 1), 1))
  return entries.filter((entry) => new Date(entry.createdAt) >= start)
}

export const aggregateByMonth = (entries: LedgerEntry[]): MonthlyAggregate[] => {
  const byMonth = new Map<string, MonthlyAggregate>()

  for (const entry of entries) {
    const key = monthKey(new Date(entry.createdAt))
    if (!byMonth.has(key)) {
      byMonth.set(key, { month: key, income: 0, expense: 0, net: 0 })
    }
    const bucket = byMonth.get(key)!
    if (entry.amount >= 0) {
      bucket.income += entry.amount
    } else {
      bucket.expense += Math.abs(entry.amount)
    }
    bucket.net += entry.amount
  }

  return [...byMonth.values()].sort((a, b) => a.month.localeCompare(b.month))
}

export const mapForFilter = (aggregate: MonthlyAggregate[], filter: ReportFilter) => {
  return aggregate.map((item) => ({
    month: item.month,
    value:
      filter === 'income'
        ? item.income
        : filter === 'expense'
          ? item.expense
          : filter === 'net'
            ? item.net
            : item.income - item.expense
  }))
}

export const summarize = (entries: LedgerEntry[]) => {
  const income = entries.filter((entry) => entry.amount >= 0).reduce((sum, entry) => sum + entry.amount, 0)
  const expense = entries.filter((entry) => entry.amount < 0).reduce((sum, entry) => sum + Math.abs(entry.amount), 0)
  return {
    income,
    expense,
    net: income - expense
  }
}
