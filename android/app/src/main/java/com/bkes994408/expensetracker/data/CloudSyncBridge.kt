package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseCategory
import java.util.UUID

sealed interface SyncEntityType {
    data object Expense : SyncEntityType
    data object Category : SyncEntityType
}

enum class SyncOperation {
    UPSERT,
    DELETE,
}

data class SyncMutation(
    val entityType: SyncEntityType,
    val operation: SyncOperation,
    val entityId: UUID,
)

data class CloudSnapshot(
    val expenses: List<Expense>,
    val categories: List<ExpenseCategory>,
)

interface CloudSyncQueue {
    suspend fun enqueue(mutation: SyncMutation)
}

interface CloudPullSource {
    suspend fun pullLatest(): CloudSnapshot?
}

class NoopCloudSyncQueue : CloudSyncQueue {
    override suspend fun enqueue(mutation: SyncMutation) = Unit
}

class NoopCloudPullSource : CloudPullSource {
    override suspend fun pullLatest(): CloudSnapshot? = null
}
