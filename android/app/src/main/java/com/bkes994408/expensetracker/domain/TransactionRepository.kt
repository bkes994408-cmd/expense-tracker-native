package com.bkes994408.expensetracker.domain

import kotlinx.coroutines.flow.Flow

interface TransactionRepository {
    fun observeAll(): Flow<List<Transaction>>

    suspend fun add(amountCents: Long, note: String, occurredAtEpochMillis: Long): Long

    suspend fun deleteById(id: Long)
}
