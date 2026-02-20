package com.bkes994408.expensetracker.category

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CategoryRepositoryImplTest {

    @Test
    fun addCategory_appendsWithIncrementedSortOrder() = runTest {
        val dao = FakeCategoryDao(
            mutableListOf(
                CategoryEntity(id = 1, name = "Food", sortOrder = 0),
                CategoryEntity(id = 2, name = "Transport", sortOrder = 1),
            )
        )
        val repo = CategoryRepositoryImpl(dao)

        repo.add("  Utility  ")

        val all = dao.getAll().sortedBy { it.sortOrder }
        assertEquals(3, all.size)
        assertEquals("Utility", all.last().name)
        assertEquals(2, all.last().sortOrder)
    }

    @Test
    fun archiveCategory_marksArchivedAndHiddenFromActive() = runTest {
        val dao = FakeCategoryDao(
            mutableListOf(
                CategoryEntity(id = 1, name = "Food", sortOrder = 0),
                CategoryEntity(id = 2, name = "Transport", sortOrder = 1),
            )
        )
        val repo = CategoryRepositoryImpl(dao)

        repo.archive(1)

        val all = dao.getAll()
        assertTrue(all.first { it.id == 1L }.isArchived)
        val active = dao.observeActiveState().value
        assertEquals(listOf("Transport"), active.map { it.name })
    }

    @Test
    fun moveDown_swapsSortOrderBetweenNeighbors() = runTest {
        val dao = FakeCategoryDao(
            mutableListOf(
                CategoryEntity(id = 1, name = "Food", sortOrder = 0),
                CategoryEntity(id = 2, name = "Transport", sortOrder = 1),
                CategoryEntity(id = 3, name = "Utility", sortOrder = 2),
            )
        )
        val repo = CategoryRepositoryImpl(dao)

        repo.move(1, MoveDirection.Down)

        val ordered = dao.getAll().filter { !it.isArchived }.sortedBy { it.sortOrder }.map { it.id }
        assertEquals(listOf(2L, 1L, 3L), ordered)
    }
}

private class FakeCategoryDao(initial: MutableList<CategoryEntity>) : CategoryDao {
    private val entities = initial
    private val activeFlow = MutableStateFlow(currentActive())
    private var nextId = (initial.maxOfOrNull { it.id } ?: 0L) + 1L

    override fun observeActive(): Flow<List<CategoryEntity>> = activeFlow

    fun observeActiveState(): MutableStateFlow<List<CategoryEntity>> = activeFlow

    override suspend fun getAll(): List<CategoryEntity> = entities.toList()

    override suspend fun getMaxSortOrder(): Int = entities.maxOfOrNull { it.sortOrder } ?: -1

    override suspend fun insert(entity: CategoryEntity): Long {
        val id = nextId++
        entities += entity.copy(id = id)
        emit()
        return id
    }

    override suspend fun update(entity: CategoryEntity) {
        val idx = entities.indexOfFirst { it.id == entity.id }
        if (idx >= 0) {
            entities[idx] = entity
            emit()
        }
    }

    private fun currentActive(): List<CategoryEntity> =
        entities.filter { !it.isArchived }.sortedBy { it.sortOrder }

    private fun emit() {
        activeFlow.value = currentActive()
    }
}
