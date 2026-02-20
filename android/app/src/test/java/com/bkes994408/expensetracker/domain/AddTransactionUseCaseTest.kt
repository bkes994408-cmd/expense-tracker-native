package com.bkes994408.expensetracker.domain

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

private class FakeRepo : TransactionRepository {
    var lastAdd: Triple<Long, String, Long>? = null

    override fun observeAll(): Flow<List<Transaction>> = flowOf(emptyList())

    override suspend fun add(amountCents: Long, note: String, occurredAtEpochMillis: Long): Long {
        lastAdd = Triple(amountCents, note, occurredAtEpochMillis)
        return 123L
    }

    override suspend fun deleteById(id: Long) = Unit
}

class AddTransactionUseCaseTest {
    @Test
    fun trimsNote_andReturnsId() = runBlocking {
        val repo = FakeRepo()
        val useCase = AddTransactionUseCase(repo)

        val id = useCase(amountCents = 1000, note = "  lunch ", occurredAtEpochMillis = 1L)

        assertEquals(123L, id)
        assertEquals(Triple(1000L, "lunch", 1L), repo.lastAdd)
    }

    @Test
    fun throwsWhenAmountIsZero() {
        val repo = FakeRepo()
        val useCase = AddTransactionUseCase(repo)

        assertThrows(IllegalArgumentException::class.java) {
            runBlocking {
                useCase(amountCents = 0L, note = "bad", occurredAtEpochMillis = 1L)
            }
        }
    }
}
