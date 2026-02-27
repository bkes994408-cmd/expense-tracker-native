package com.bkes994408.expensetracker.category

import kotlinx.coroutines.flow.Flow

interface CategoryRepository {
    fun observeActive(): Flow<List<CategoryEntity>>
    suspend fun add(name: String)
    suspend fun archive(id: Long)
    suspend fun move(id: Long, direction: MoveDirection)
}

enum class MoveDirection { Up, Down }

class CategoryRepositoryImpl(
    private val dao: CategoryDao,
) : CategoryRepository {
    override fun observeActive(): Flow<List<CategoryEntity>> = dao.observeActive()

    override suspend fun add(name: String) {
        val maxOrder = dao.getMaxSortOrder()
        dao.insert(CategoryEntity(name = name.trim(), sortOrder = maxOrder + 1))
    }

    override suspend fun archive(id: Long) {
        val all = dao.getAll()
        val target = all.firstOrNull { it.id == id } ?: return
        if (target.isArchived) return
        dao.update(target.copy(isArchived = true))
    }

    override suspend fun move(id: Long, direction: MoveDirection) {
        val active = dao.getAll().filter { !it.isArchived }.sortedBy { it.sortOrder }
        val index = active.indexOfFirst { it.id == id }
        if (index == -1) return

        val swapIndex = when (direction) {
            MoveDirection.Up -> index - 1
            MoveDirection.Down -> index + 1
        }
        if (swapIndex !in active.indices) return

        val current = active[index]
        val target = active[swapIndex]

        dao.update(current.copy(sortOrder = target.sortOrder))
        dao.update(target.copy(sortOrder = current.sortOrder))
    }
}
