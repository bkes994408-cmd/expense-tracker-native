package com.bkes994408.expensetracker.data

import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseCategory
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant

class FileExpenseStoreTest {
    @Test
    fun readAllReturnsEmptyWhenFileDoesNotExist() = runTest {
        val fileOps = FakeFileOps(exists = false, content = "")
        val store = FileExpenseStore(fileOps)

        val expenses = store.readAll()

        assertTrue(expenses.isEmpty())
    }

    @Test
    fun readAllReturnsPersistedContentWhenFileExists() = runTest {
        val persistedJson = """
            [
              {"title":"Salary","amount":"42000","createdAt":"2026-03-11T09:00:00Z"},
              {"title":"Food","amount":"-8500","createdAt":"2026-03-10T09:00:00Z"}
            ]
        """.trimIndent()
        val fileOps = FakeFileOps(exists = true, content = persistedJson)
        val store = FileExpenseStore(fileOps)

        val expenses = store.readAll()

        assertEquals(2, expenses.size)
        assertEquals("Salary", expenses[0].title)
        assertEquals(BigDecimal("42000"), expenses[0].amount)
        assertEquals(Instant.parse("2026-03-11T09:00:00Z"), expenses[0].createdAt)
        assertEquals("Food", expenses[1].title)
        assertEquals(BigDecimal("-8500"), expenses[1].amount)
    }

    @Test
    fun readAllMatchesContentAfterWrite() = runTest {
        val fileOps = FakeFileOps(exists = false, content = "")
        val persisted = listOf(
            Expense(title = "Freelance", amount = BigDecimal("18000"), createdAt = Instant.parse("2026-03-01T09:00:00Z")),
            Expense(title = "Transport", amount = BigDecimal("-3200"), createdAt = Instant.parse("2026-03-02T09:00:00Z")),
        )

        val store = FileExpenseStore(fileOps)
        store.writeAll(persisted)
        val loaded = store.readAll()

        assertEquals(persisted.map { Triple(it.title, it.amount, it.createdAt) }, loaded.map { Triple(it.title, it.amount, it.createdAt) })
    }

    @Test
    fun writeAndReadCategoriesRoundTrip() = runTest {
        val fileOps = FakeFileOps(exists = false, content = "")
        val store = FileExpenseStore(fileOps)
        val categories = listOf(
            ExpenseCategory(name = "Food", updatedAt = Instant.parse("2026-03-05T09:00:00Z")),
            ExpenseCategory(name = "Transport", updatedAt = Instant.parse("2026-03-06T09:00:00Z")),
        )

        store.writeAllCategories(categories)
        val loaded = store.readAllCategories()

        assertEquals(categories.map { it.name }, loaded.map { it.name })
        assertEquals(categories.map { it.updatedAt }, loaded.map { it.updatedAt })
    }
}

private class FakeFileOps(
    private var exists: Boolean,
    private var content: String,
) : FileOps {
    override fun exists(): Boolean = exists

    override fun readText(): String = content

    override fun writeText(text: String) {
        content = text
        exists = true
    }
}
