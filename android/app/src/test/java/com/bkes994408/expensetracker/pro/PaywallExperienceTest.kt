package com.bkes994408.expensetracker.pro

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class PaywallExperienceTest {
    @Test
    fun budgetTrigger_returnsBudgetFocusedCopy() {
        val content = PaywallExperience.content("budget_limit")

        assertEquals("解鎖不限分類預算", content.headline)
        assertTrue(content.recommendedPlanLabel.contains("年付"))
    }

    @Test
    fun advancedReportTrigger_mentionsLongRangeTrend() {
        val content = PaywallExperience.content("advanced_report_3m")

        assertEquals("解鎖長區間趨勢分析", content.headline)
        assertTrue(content.subheadline.contains("3/6/12"))
    }
}
