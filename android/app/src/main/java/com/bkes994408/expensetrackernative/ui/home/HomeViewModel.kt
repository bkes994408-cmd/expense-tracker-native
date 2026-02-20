package com.bkes994408.expensetrackernative.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bkes994408.expensetrackernative.domain.GetTransactionsUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class HomeUiState(
    val title: String = "Expense Tracker Native",
    val totalExpense: Double = 0.0,
)

class HomeViewModel(
    private val getTransactionsUseCase: GetTransactionsUseCase,
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    fun load() {
        viewModelScope.launch {
            val total = getTransactionsUseCase().sumOf { it.amount }
            _uiState.value = HomeUiState(totalExpense = total)
        }
    }
}
