package com.bkes994408.expensetracker.ui

import com.bkes994408.expensetracker.pro.ReportRange

sealed interface RangeSelectionResult {
    data class RangeSelected(val range: ReportRange) : RangeSelectionResult
    data class PaywallRequired(val trigger: String) : RangeSelectionResult
}

object HomeReportController {
    fun nextRange(current: ReportRange, isPro: Boolean): RangeSelectionResult {
        val next = when (current) {
            ReportRange.ONE_MONTH -> ReportRange.THREE_MONTHS
            ReportRange.THREE_MONTHS -> ReportRange.SIX_MONTHS
            ReportRange.SIX_MONTHS -> ReportRange.TWELVE_MONTHS
            ReportRange.TWELVE_MONTHS -> ReportRange.ONE_MONTH
        }

        if (!isPro && next.months > 1) {
            return RangeSelectionResult.PaywallRequired("advanced_report_3m")
        }
        return RangeSelectionResult.RangeSelected(next)
    }
}
