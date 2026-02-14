package com.bkes994408.expensetracker.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bkes994408.expensetracker.domain.AddTransactionUseCase
import com.bkes994408.expensetracker.domain.DeleteTransactionUseCase
import com.bkes994408.expensetracker.domain.ObserveTransactionsUseCase
import com.bkes994408.expensetracker.domain.Transaction
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class AppViewModel(
    private val observeTransactions: ObserveTransactionsUseCase,
    private val addTransaction: AddTransactionUseCase,
    private val deleteTransaction: DeleteTransactionUseCase,
) : ViewModel() {

    val transactions: StateFlow<List<Transaction>> = observeTransactions()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun add(amountCents: Long, note: String, occurredAtEpochMillis: Long) {
        viewModelScope.launch {
            addTransaction(
                amountCents = amountCents,
                note = note,
                occurredAtEpochMillis = occurredAtEpochMillis,
            )
        }
    }

    fun delete(id: Long) {
        viewModelScope.launch { deleteTransaction(id) }
    }
}
