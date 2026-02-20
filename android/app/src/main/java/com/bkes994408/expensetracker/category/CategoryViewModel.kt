package com.bkes994408.expensetracker.category

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class CategoryUiModel(
    val id: Long,
    val name: String,
)

class CategoryViewModel(
    private val repository: CategoryRepository,
) : ViewModel() {
    private val _nameInput = MutableStateFlow("")
    val nameInput = _nameInput.asStateFlow()

    val categories: StateFlow<List<CategoryUiModel>> = repository.observeActive()
        .map { list -> list.map { CategoryUiModel(id = it.id, name = it.name) } }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun onNameChanged(value: String) {
        _nameInput.value = value
    }

    fun addCategory() {
        val name = _nameInput.value.trim()
        if (name.isBlank()) return
        viewModelScope.launch {
            repository.add(name)
            _nameInput.value = ""
        }
    }

    fun archive(id: Long) {
        viewModelScope.launch { repository.archive(id) }
    }

    fun moveUp(id: Long) {
        viewModelScope.launch { repository.move(id, MoveDirection.Up) }
    }

    fun moveDown(id: Long) {
        viewModelScope.launch { repository.move(id, MoveDirection.Down) }
    }

    companion object {
        fun factory(repository: CategoryRepository): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T {
                    return CategoryViewModel(repository) as T
                }
            }
    }
}
