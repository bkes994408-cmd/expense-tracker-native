package com.bkes994408.expensetracker.data.repo

import com.bkes994408.expensetracker.data.db.TransactionDao
import com.bkes994408.expensetracker.data.db.TransactionEntity
import com.bkes994408.expensetracker.domain.Transaction
import com.bkes994408.expensetracker.domain.TransactionRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class RoomTransactionRepository(
    private val dao: TransactionDao,
) : TransactionRepository {

    override fun observeAll(): Flow<List<Transaction>> = dao.observeAll().map { list ->
        list.map { entity ->
            Transaction(
                id = entity.id,
                amountCents = entity.amountCents,
                note = entity.note,
                occurredAtEpochMillis = entity.occurredAtEpochMillis,
            )
        }
    }

    override suspend fun add(amountCents: Long, note: String, occurredAtEpochMillis: Long): Long {
        return dao.insert(
            TransactionEntity(
                amountCents = amountCents,
                note = note,
                occurredAtEpochMillis = occurredAtEpochMillis,
            )
        )
    }

    override suspend fun deleteById(id: Long) {
        dao.deleteById(id)
    }
}
