package com.bkes994408.expensetracker.pro

import com.bkes994408.expensetracker.db.ExpenseLedger
import com.bkes994408.expensetracker.db.ExpenseSnapshotManager
import com.bkes994408.expensetracker.domain.Expense
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.ZoneOffset

class Iteration6FeatureTest {
    @Test
    fun annualWrapped_buildsTotalsAndHighlights() {
        val expenses = listOf(
            Expense(title = "Salary", amount = BigDecimal("50000"), createdAt = Instant.parse("2025-01-03T00:00:00Z")),
            Expense(title = "Lunch", amount = BigDecimal("-3000"), createdAt = Instant.parse("2025-01-10T00:00:00Z")),
            Expense(title = "Salary", amount = BigDecimal("50000"), createdAt = Instant.parse("2025-02-03T00:00:00Z")),
            Expense(title = "Uber", amount = BigDecimal("-2000"), createdAt = Instant.parse("2025-02-10T00:00:00Z")),
        )

        val report = AnnualWrappedCalculator.build(expenses, 2025, ZoneOffset.UTC)

        assertNotNull(report)
        assertEquals(BigDecimal("100000"), report?.totalIncome)
        assertEquals(BigDecimal("5000"), report?.totalExpense)
        assertEquals("餐飲", report?.topExpenseCategory)
    }

    @Test
    fun snapshotManager_restoresLedgerEntries() {
        val ledger = ExpenseLedger()
        ledger.addExpense("Lunch", BigDecimal("-120"))
        ledger.addExpense("Taxi", BigDecimal("-90"))

        val manager = ExpenseSnapshotManager(ledger)
        val snapshot = manager.createSnapshot()

        ledger.replaceAll(emptyList())
        assertTrue(ledger.entries.value.isEmpty())

        val restored = manager.restoreSnapshot(snapshot)

        assertTrue(restored)
        assertEquals(2, ledger.entries.value.size)
    }

    @Test
    fun retentionStrategy_trialNearExpiry_returnsWinbackOffer() = runTest {
        val now = 1_700_000_000_000L
        val storage = InMemoryEntitlementStorageIteration6()
        val store = ProEntitlementStore(
            storage = storage,
            purchaseService = MockProPurchaseService(purchaseResult = Result.success(ProTier.TRIAL)),
            nowProvider = { now },
        )
        store.startTrial()

        storage.writeTrialExpireAtMillis(now + 24L * 60L * 60L * 1000L)

        val strategy = store.retentionStrategy(now)
        assertEquals("trial_last48h", strategy?.offerCode)
    }
}

private class InMemoryEntitlementStorageIteration6 : EntitlementStorage {
    private var tierName: String = ProTier.FREE.name
    private var trialExpireAtMillis: Long? = null

    override fun readTierName(): String = tierName

    override fun writeTierName(value: String) {
        tierName = value
    }

    override fun readTrialExpireAtMillis(): Long? = trialExpireAtMillis

    override fun writeTrialExpireAtMillis(value: Long?) {
        trialExpireAtMillis = value
    }
}
