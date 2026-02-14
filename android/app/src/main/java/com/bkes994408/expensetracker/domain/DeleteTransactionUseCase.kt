package com.bkes994408.expensetracker.domain

class DeleteTransactionUseCase(
    private val repository: TransactionRepository,
) {
    suspend operator fun invoke(id: Long) {
        repository.deleteById(id)
    }
}
