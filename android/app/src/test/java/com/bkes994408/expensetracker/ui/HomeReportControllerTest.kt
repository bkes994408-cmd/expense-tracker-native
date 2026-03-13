package com.bkes994408.expensetracker.ui

import com.bkes994408.expensetracker.pro.ReportRange
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class HomeReportControllerTest {
    @Test
    fun freeTierFromOneMonthReturnsPaywall() {
        val result = HomeReportController.nextRange(ReportRange.ONE_MONTH, isPro = false)

        assertTrue(result is RangeSelectionResult.PaywallRequired)
        assertEquals("advanced_report_3m", (result as RangeSelectionResult.PaywallRequired).trigger)
    }

    @Test
    fun proTierCyclesAllRangesAndBackToOneMonth() {
        val threeMonths = HomeReportController.nextRange(ReportRange.ONE_MONTH, isPro = true)
        assertEquals(ReportRange.THREE_MONTHS, (threeMonths as RangeSelectionResult.RangeSelected).range)

        val sixMonths = HomeReportController.nextRange(threeMonths.range, isPro = true)
        assertEquals(ReportRange.SIX_MONTHS, (sixMonths as RangeSelectionResult.RangeSelected).range)

        val twelveMonths = HomeReportController.nextRange(sixMonths.range, isPro = true)
        assertEquals(ReportRange.TWELVE_MONTHS, (twelveMonths as RangeSelectionResult.RangeSelected).range)

        val oneMonth = HomeReportController.nextRange(twelveMonths.range, isPro = true)
        assertEquals(ReportRange.ONE_MONTH, (oneMonth as RangeSelectionResult.RangeSelected).range)
    }
}
