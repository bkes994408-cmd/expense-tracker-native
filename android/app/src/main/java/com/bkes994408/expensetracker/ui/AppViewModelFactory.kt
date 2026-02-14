package com.bkes994408.expensetracker.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.bkes994408.expensetracker.domain.AddTransactionUseCase
import com.bkes994408.expensetracker.domain.DeleteTransactionUseCase
import com.bkes994408.expensetracker.domain.ObserveTransactionsUseCase

class AppViewModelFactory(
    private val observeTransactions: ObserveTransactionsUseCase,
    private val addTransaction: AddTransactionUseCase,
    private val deleteTransaction: DeleteTransactionUseCase,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return AppViewModel(
            observeTransactions = observeTransactions,
            addTransaction = addTransaction,
            deleteTransaction = deleteTransaction,
        ) as T
    }
}
