package com.bkes994408.expensetracker.domain

class AddTransactionUseCase(
    private val repository: TransactionRepository,
) {
    suspend operator fun invoke(
        amountCents: Long,
        note: String,
        occurredAtEpochMillis: Long,
    ): Long {
        if (amountCents == 0L) {
            throw IllegalArgumentException("Amount must not be zero")
        }
        return repository.add(
            amountCents = amountCents,
            note = note.trim(),
            occurredAtEpochMillis = occurredAtEpochMillis,
        )
    }
}
