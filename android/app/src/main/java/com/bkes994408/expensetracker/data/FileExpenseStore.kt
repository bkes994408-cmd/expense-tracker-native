package com.bkes994408.expensetracker.data

import android.content.Context
import com.bkes994408.expensetracker.domain.Expense
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.math.BigDecimal
import java.time.Instant
import java.time.temporal.ChronoUnit

class FileExpenseStore(
    context: Context,
    private val nowProvider: () -> Instant = { Instant.now() },
) : ExpenseStore {
    private val appContext = context.applicationContext
    private val mutex = Mutex()
    private val fileName = "expenses.json"

    override suspend fun readAll(): List<Expense> = withContext(Dispatchers.IO) {
        mutex.withLock {
            if (!appContext.fileList().contains(fileName)) {
                persist(seedExpenses())
            }
            val raw = appContext.openFileInput(fileName).bufferedReader().use { it.readText() }
            parse(raw)
        }
    }

    private fun persist(expenses: List<Expense>) {
        val json = JSONArray().apply {
            expenses.forEach { expense ->
                put(
                    JSONObject().apply {
                        put("title", expense.title)
                        put("amount", expense.amount.toPlainString())
                        put("createdAt", expense.createdAt.toString())
                    }
                )
            }
        }
        appContext.openFileOutput(fileName, Context.MODE_PRIVATE).bufferedWriter().use { it.write(json.toString()) }
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

    private fun seedExpenses(): List<Expense> {
        val now = nowProvider()
        return listOf(
            Expense(title = "Salary", amount = BigDecimal("42000"), createdAt = now.minus(5, ChronoUnit.DAYS)),
            Expense(title = "Food", amount = BigDecimal("-8500"), createdAt = now.minus(4, ChronoUnit.DAYS)),
            Expense(title = "Transport", amount = BigDecimal("-3200"), createdAt = now.minus(35, ChronoUnit.DAYS)),
            Expense(title = "Freelance", amount = BigDecimal("18000"), createdAt = now.minus(62, ChronoUnit.DAYS)),
        )
    }
}
