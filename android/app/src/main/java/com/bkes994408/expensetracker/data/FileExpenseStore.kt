package com.bkes994408.expensetracker.data

import android.content.Context
import com.bkes994408.expensetracker.domain.Expense
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

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
            if (!fileOps.exists()) {
                return@withLock emptyList()
            }
            val raw = fileOps.readText()
            parse(raw)
        }
    }

    private fun parse(raw: String): List<Expense> {
        if (raw.isBlank()) return emptyList()
        val array = JSONArray(raw)
        return buildList {
            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                add(
                    Expense(
                        title = item.getString("title"),
                        amount = item.getString("amount").toBigDecimal(),
                        createdAt = Instant.parse(item.getString("createdAt")),
                    )
                )
            }
        }
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
