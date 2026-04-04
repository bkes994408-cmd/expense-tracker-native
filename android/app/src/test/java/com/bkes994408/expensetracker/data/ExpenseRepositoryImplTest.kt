package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseCategory
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

class ExpenseRepositoryImplTest {
    @Test
    fun fetchExpensesReturnsPersistedDataFromStore() = runTest {
        val persisted = listOf(
            Expense(title = "Salary", amount = BigDecimal("50000"), createdAt = Instant.parse("2026-03-11T09:00:00Z")),
            Expense(title = "Rent", amount = BigDecimal("-15000"), createdAt = Instant.parse("2026-03-10T09:00:00Z")),
        )
        val repository = ExpenseRepositoryImpl(FakeExpenseStore(expenses = persisted))

        val result = repository.fetchExpenses()

        assertEquals(persisted, result)
    }

    @Test
    fun addExpenseEnqueuesCloudMutation() = runTest {
        val store = FakeExpenseStore()
        val queue = FakeCloudSyncQueue()
        val repository = ExpenseRepositoryImpl(store, queue, NoopCloudPullSource())
        val expense = Expense(title = "Coffee", amount = BigDecimal("-120"))

        repository.addExpense(expense)

        assertEquals(listOf(expense), store.expenses)
        assertEquals(1, queue.mutations.size)
        assertEquals(SyncEntityType.Expense, queue.mutations.first().entityType)
        assertEquals(SyncOperation.UPSERT, queue.mutations.first().operation)
    }
}

private class FakeExpenseStore(
    expenses: List<Expense> = emptyList(),
    categories: List<ExpenseCategory> = emptyList(),
) : ExpenseStore {
    var expenses: List<Expense> = expenses
        private set
    private var categories: List<ExpenseCategory> = categories

    override suspend fun readAll(): List<Expense> = expenses

    override suspend fun writeAll(expenses: List<Expense>) {
        this.expenses = expenses
    }

    override suspend fun readAllCategories(): List<ExpenseCategory> = categories

    override suspend fun writeAllCategories(categories: List<ExpenseCategory>) {
        this.categories = categories
    }

    override suspend fun upsertExpense(expense: Expense) {
        expenses = expenses.filterNot { it.id == expense.id } + expense
    }

    override suspend fun deleteExpense(id: UUID) {
        expenses = expenses.filterNot { it.id == id }
    }

    override suspend fun upsertCategory(category: ExpenseCategory) {
        categories = categories.filterNot { it.id == category.id } + category
    }

    override suspend fun deleteCategory(id: UUID) {
        categories = categories.filterNot { it.id == id }
    }
}

private class FakeCloudSyncQueue : CloudSyncQueue {
    val mutations = mutableListOf<SyncMutation>()

    override suspend fun enqueue(mutation: SyncMutation) {
        mutations += mutation
    }
}
