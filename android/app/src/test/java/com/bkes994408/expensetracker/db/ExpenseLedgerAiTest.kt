package com.bkes994408.expensetracker.db

import com.bkes994408.expensetracker.ai.KeywordCategoryClassifier
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class ExpenseLedgerAiTest {
    @Test
    fun addExpense_withoutCategory_usesOnDeviceClassification() {
        val ledger = ExpenseLedger(KeywordCategoryClassifier())

        ledger.addExpense(title = "Uber to office", amount = BigDecimal("-180"))

        val entry = ledger.entries.value.single()
        assertEquals("交通", entry.category)
    }

    @Test
    fun suggestBudgets_includesTrendAwareDraft() {
        val ledger = ExpenseLedger(KeywordCategoryClassifier())
        val now = LocalDate.of(2026, 3, 20)

        ledger.replaceAll(
            listOf(
                expense("早餐", "-120", LocalDate.of(2025, 10, 10), "餐飲"),
                expense("早餐", "-220", LocalDate.of(2025, 11, 10), "餐飲"),
                expense("早餐", "-320", LocalDate.of(2025, 12, 10), "餐飲"),
                expense("早餐", "-420", LocalDate.of(2026, 1, 10), "餐飲"),
                expense("早餐", "-520", LocalDate.of(2026, 2, 10), "餐飲"),
            ),
        )

        val suggestions = ledger.suggestBudgets(now)
        assertTrue(suggestions.isNotEmpty())
        assertTrue(suggestions.first().trend > BigDecimal.ZERO)
        assertTrue(suggestions.first().suggestedBudget >= BigDecimal("300"))
    }

    @Test
    fun detectOverspend_forecastsCurrentPace() {
        val ledger = ExpenseLedger(KeywordCategoryClassifier())
        val now = LocalDate.of(2026, 3, 20)

        ledger.replaceAll(
            listOf(
                expense("租金", "-1200", LocalDate.of(2025, 10, 5), "居家"),
                expense("租金", "-1200", LocalDate.of(2025, 11, 5), "居家"),
                expense("租金", "-1200", LocalDate.of(2025, 12, 5), "居家"),
                expense("租金", "-1200", LocalDate.of(2026, 1, 5), "居家"),
                expense("租金", "-1200", LocalDate.of(2026, 2, 5), "居家"),
                expense("租金", "-1100", LocalDate.of(2026, 3, 2), "居家"),
            ),
        )

        val alerts = ledger.detectOverspend(now)
        assertTrue(alerts.any { it.category == "居家" })
    }

    private fun expense(title: String, amount: String, date: LocalDate, category: String): ExpenseLedger.Entry {
        val instant = date.atStartOfDay(ZoneId.systemDefault()).toInstant()
        return ExpenseLedger.Entry(title = title, amount = BigDecimal(amount), createdAt = instant, category = category)
    }
}
