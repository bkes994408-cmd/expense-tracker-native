export type LedgerEntry = {
  id: string
  title: string
  amount: number
  category: string
  createdAt: string
}

export type ReportFilter = 'all' | 'income' | 'expense' | 'net'

export type PeriodOption = 1 | 3 | 6 | 12
