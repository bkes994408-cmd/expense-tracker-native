import type { PeriodOption } from '../types'

export type EntitlementPlan = 'free' | 'pro'

export const canAccessPeriod = (plan: EntitlementPlan, period: PeriodOption): boolean => {
  if (plan === 'pro') return true
  return period === 1
}

export const availablePeriodsForPlan = (plan: EntitlementPlan, options: PeriodOption[]): PeriodOption[] =>
  options.filter((option) => canAccessPeriod(plan, option))
