package com.bkes994408.expensetracker.data

import android.content.Context
import com.bkes994408.expensetracker.domain.Expense
import com.bkes994408.expensetracker.domain.ExpenseCategory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant
import java.util.UUID

class FileExpenseStore internal constructor(
    private val fileOps: FileOps,
) : ExpenseStore {
    constructor(
        context: Context,
        fileName: String = "expenses.json",
    ) : this(ContextFileOps(context.applicationContext, fileName))

    private val mutex = Mutex()

    override suspend fun readAll(): List<Expense> = withContext(Dispatchers.IO) {
        mutex.withLock {
            readPayload().expenses
        }
    }

    override suspend fun writeAll(expenses: List<Expense>) = withContext(Dispatchers.IO) {
        mutex.withLock {
            val payload = readPayload().copy(expenses = expenses)
            writePayload(payload)
        }
    }

    override suspend fun readAllCategories(): List<ExpenseCategory> = withContext(Dispatchers.IO) {
        mutex.withLock {
            readPayload().categories
        }
    }

    override suspend fun writeAllCategories(categories: List<ExpenseCategory>) = withContext(Dispatchers.IO) {
        mutex.withLock {
            val payload = readPayload().copy(categories = categories)
            writePayload(payload)
        }
    }

    override suspend fun upsertExpense(expense: Expense) = withContext(Dispatchers.IO) {
        mutex.withLock {
            val payload = readPayload()
            val updated = payload.expenses.filterNot { it.id == expense.id } + expense
            writePayload(payload.copy(expenses = updated))
        }
    }

    override suspend fun deleteExpense(id: UUID) = withContext(Dispatchers.IO) {
        mutex.withLock {
            val payload = readPayload()
            writePayload(payload.copy(expenses = payload.expenses.filterNot { it.id == id }))
        }
    }

    override suspend fun upsertCategory(category: ExpenseCategory) = withContext(Dispatchers.IO) {
        mutex.withLock {
            val payload = readPayload()
            val updated = payload.categories.filterNot { it.id == category.id } + category
            writePayload(payload.copy(categories = updated))
        }
    }

    override suspend fun deleteCategory(id: UUID) = withContext(Dispatchers.IO) {
        mutex.withLock {
            val payload = readPayload()
            writePayload(payload.copy(categories = payload.categories.filterNot { it.id == id }))
        }
    }

    private fun readPayload(): Payload {
        if (!fileOps.exists()) return Payload()
        val raw = fileOps.readText()
        return parsePayload(raw)
    }

    private fun writePayload(payload: Payload) {
        val root = JSONObject()
            .put("expenses", payload.expenses.toExpenseJsonArray())
            .put("categories", payload.categories.toCategoryJsonArray())
        fileOps.writeText(root.toString())
    }

    private fun parsePayload(raw: String): Payload {
        if (raw.isBlank()) return Payload()

        return runCatching {
            val json = JSONObject(raw)
            Payload(
                expenses = parseExpenseArray(json.optJSONArray("expenses") ?: JSONArray()),
                categories = parseCategoryArray(json.optJSONArray("categories") ?: JSONArray()),
            )
        }.getOrElse {
            // backward compatibility: legacy payload is plain expense array
            Payload(expenses = parseExpenseArray(JSONArray(raw)))
        }
    }

    private fun parseExpenseArray(array: JSONArray): List<Expense> = buildList {
        for (index in 0 until array.length()) {
            val item = array.optJSONObject(index) ?: continue
            add(
                Expense(
                    id = item.optString("id").takeIf { it.isNotBlank() }?.let(UUID::fromString) ?: UUID.randomUUID(),
                    title = item.getString("title"),
                    amount = item.getString("amount").toBigDecimal(),
                    createdAt = Instant.parse(item.getString("createdAt")),
                )
            )
        }
    }

    private fun parseCategoryArray(array: JSONArray): List<ExpenseCategory> = buildList {
        for (index in 0 until array.length()) {
            val item = array.optJSONObject(index) ?: continue
            val name = item.optString("name").trim()
            if (name.isBlank()) continue
            add(
                ExpenseCategory(
                    id = item.optString("id").takeIf { it.isNotBlank() }?.let(UUID::fromString) ?: UUID.randomUUID(),
                    name = name,
                    updatedAt = item.optString("updatedAt")
                        .takeIf { it.isNotBlank() }
                        ?.let(Instant::parse)
                        ?: Instant.now(),
                )
            )
        }
    }

    private data class Payload(
        val expenses: List<Expense> = emptyList(),
        val categories: List<ExpenseCategory> = emptyList(),
    )
}

private fun List<Expense>.toExpenseJsonArray(): JSONArray = JSONArray().apply {
    forEach { expense ->
        put(
            JSONObject()
                .put("id", expense.id.toString())
                .put("title", expense.title)
                .put("amount", expense.amount.toPlainString())
                .put("createdAt", expense.createdAt.toString())
        )
    }
}

private fun List<ExpenseCategory>.toCategoryJsonArray(): JSONArray = JSONArray().apply {
    forEach { category ->
        put(
            JSONObject()
                .put("id", category.id.toString())
                .put("name", category.name)
                .put("updatedAt", category.updatedAt.toString())
        )
    }
}

internal interface FileOps {
    fun exists(): Boolean
    fun readText(): String
    fun writeText(text: String)
}

private class ContextFileOps(
    private val context: Context,
    private val fileName: String,
) : FileOps {
    override fun exists(): Boolean = context.fileList().contains(fileName)

    override fun readText(): String =
        context.openFileInput(fileName).bufferedReader().use { it.readText() }

    override fun writeText(text: String) {
        context.openFileOutput(fileName, Context.MODE_PRIVATE).bufferedWriter().use { it.write(text) }
    }
}
