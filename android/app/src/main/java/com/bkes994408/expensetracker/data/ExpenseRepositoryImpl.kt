package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseCategory
import com.bkes994408.expensetracker.domain.ExpenseRepository
import java.util.UUID

class ExpenseRepositoryImpl(
    private val expenseStore: ExpenseStore,
    private val cloudSyncQueue: CloudSyncQueue = NoopCloudSyncQueue(),
    private val cloudPullSource: CloudPullSource = NoopCloudPullSource(),
) : ExpenseRepository {
    override suspend fun fetchExpenses(): List<Expense> = expenseStore.readAll()

    override suspend fun fetchCategories(): List<ExpenseCategory> = expenseStore.readAllCategories()

    override suspend fun addExpense(expense: Expense) {
        expenseStore.upsertExpense(expense)
        cloudSyncQueue.enqueue(
            SyncMutation(
                entityType = SyncEntityType.Expense,
                operation = SyncOperation.UPSERT,
                entityId = expense.id,
            )
        )
    }

    override suspend fun updateExpense(expense: Expense) {
        expenseStore.upsertExpense(expense)
        cloudSyncQueue.enqueue(
            SyncMutation(
                entityType = SyncEntityType.Expense,
                operation = SyncOperation.UPSERT,
                entityId = expense.id,
            )
        )
    }

    override suspend fun deleteExpense(id: UUID) {
        expenseStore.deleteExpense(id)
        cloudSyncQueue.enqueue(
            SyncMutation(
                entityType = SyncEntityType.Expense,
                operation = SyncOperation.DELETE,
                entityId = id,
            )
        )
    }

    override suspend fun addCategory(category: ExpenseCategory) {
        expenseStore.upsertCategory(category)
        cloudSyncQueue.enqueue(
            SyncMutation(
                entityType = SyncEntityType.Category,
                operation = SyncOperation.UPSERT,
                entityId = category.id,
            )
        )
    }

    override suspend fun updateCategory(category: ExpenseCategory) {
        expenseStore.upsertCategory(category)
        cloudSyncQueue.enqueue(
            SyncMutation(
                entityType = SyncEntityType.Category,
                operation = SyncOperation.UPSERT,
                entityId = category.id,
            )
        )
    }

    override suspend fun deleteCategory(id: UUID) {
        expenseStore.deleteCategory(id)
        cloudSyncQueue.enqueue(
            SyncMutation(
                entityType = SyncEntityType.Category,
                operation = SyncOperation.DELETE,
                entityId = id,
            )
        )
    }

    override suspend fun syncFromCloud() {
        val snapshot = cloudPullSource.pullLatest() ?: return
        expenseStore.writeAll(snapshot.expenses)
        expenseStore.writeAllCategories(snapshot.categories)
    }
}
