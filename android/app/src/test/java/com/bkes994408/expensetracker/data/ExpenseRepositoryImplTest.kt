package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant

class ExpenseRepositoryImplTest {
    @Test
    fun fetchExpensesReturnsPersistedDataFromStore() = runTest {
        val persisted = listOf(
            Expense(title = "Salary", amount = BigDecimal("50000"), createdAt = Instant.parse("2026-03-11T09:00:00Z")),
            Expense(title = "Rent", amount = BigDecimal("-15000"), createdAt = Instant.parse("2026-03-10T09:00:00Z")),
        )
        val repository = ExpenseRepositoryImpl(FakeExpenseStore(persisted))

        val result = repository.fetchExpenses()

        assertEquals(persisted, result)
    }
}

private class FakeExpenseStore(
    private val items: List<Expense>,
) : ExpenseStore {
    override suspend fun readAll(): List<Expense> = items
}
