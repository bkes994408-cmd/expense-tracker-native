package com.bkes994408.expensetracker.domain

class AddTransactionUseCase(
    private val repository: TransactionRepository,
) {
    suspend operator fun invoke(
        amountCents: Long,
        note: String,
        occurredAtEpochMillis: Long,
    ): Long {
        require(amountCents != 0L) { "amountCents must not be 0" }
        return repository.add(
            amountCents = amountCents,
            note = note.trim(),
            occurredAtEpochMillis = occurredAtEpochMillis,
        )
    }
}
