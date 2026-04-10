package com.bkes994408.expensetracker.db

import com.bkes994408.expensetracker.ai.BudgetIntelligenceEngine
import com.bkes994408.expensetracker.ai.HybridCategoryClassifier
import com.bkes994408.expensetracker.ai.OnDeviceCategoryClassifier
import org.json.JSONArray
import org.json.JSONObject
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class ExpenseLedger(
    private val categoryClassifier: OnDeviceCategoryClassifier = HybridCategoryClassifier(),
) {
    data class Entry(
        val id: String = UUID.randomUUID().toString(),
        val title: String,
        val amount: BigDecimal,
        val createdAt: Instant = Instant.now(),
        val category: String = "未分類",
    )

    data class Suggestion(
        val category: String,
        val averageSpend: BigDecimal,
        val suggestedBudget: BigDecimal,
        val trend: BigDecimal,
    )

    data class Alert(
        val category: String,
        val spent: BigDecimal,
        val budget: BigDecimal,
        val ratio: BigDecimal,
        val danger: Boolean,
    )

    private val _entries = MutableStateFlow<List<Entry>>(emptyList())
    val entries: StateFlow<List<Entry>> = _entries

    fun addExpense(title: String, amount: BigDecimal, category: String? = null) {
        if (title.isBlank() || amount == BigDecimal.ZERO) return
        val resolvedCategory = category?.takeIf { it.isNotBlank() }
            ?: categoryClassifier.classify(title.trim()).category
        _entries.value = _entries.value + Entry(title = title.trim(), amount = amount, category = resolvedCategory)
    }

    fun predictCategory(title: String): OnDeviceCategoryClassifier.Prediction = categoryClassifier.classify(title)

    fun importCsv(raw: String): Pair<Int, Int> {
        val lines = raw.lines().map { it.trim() }.filter { it.isNotBlank() }
        val rows = if (lines.firstOrNull()?.contains("title", ignoreCase = true) == true) lines.drop(1) else lines
        var imported = 0
        var skipped = 0
        val newItems = mutableListOf<Entry>()

        rows.forEach { line ->
            val cols = parseCsvLine(line)
            if (cols.size < 4) {
                skipped += 1
                return@forEach
            }
            val title = cols[1].trim()
            val amount = cols[2].toBigDecimalOrNull()
            val createdAt = runCatching { Instant.parse(cols[3]) }.getOrElse { Instant.now() }
            val category = cols.getOrNull(4)?.ifBlank { "未分類" } ?: "未分類"
            if (title.isBlank() || amount == null || amount == BigDecimal.ZERO) {
                skipped += 1
                return@forEach
            }
            imported += 1
            newItems += Entry(title = title, amount = amount, createdAt = createdAt, category = category)
        }

        _entries.value = _entries.value + newItems
        return imported to skipped
    }

    fun importJson(raw: String): Pair<Int, Int> {
        val array = runCatching { JSONArray(raw) }.getOrNull() ?: return 0 to 0
        var imported = 0
        var skipped = 0
        val newItems = mutableListOf<Entry>()

        for (index in 0 until array.length()) {
            val obj = array.optJSONObject(index) ?: continue
            val title = obj.optString("title").trim()
            val amount = obj.optString("amount").toBigDecimalOrNull()
            val createdAt = runCatching { Instant.parse(obj.optString("createdAt")) }.getOrElse { Instant.now() }
            val category = obj.optString("category", "未分類").ifBlank { "未分類" }
            if (title.isBlank() || amount == null || amount == BigDecimal.ZERO) {
                skipped += 1
                continue
            }
            imported += 1
            newItems += Entry(title = title, amount = amount, createdAt = createdAt, category = category)
        }

        _entries.value = _entries.value + newItems
        return imported to skipped
    }

    fun exportCsv(): String {
        val header = "id,title,amount,createdAt,category"
        val rows = _entries.value.joinToString("\n") {
            listOf(it.id, "\"${it.title.replace("\"", "\"\"")}\"", it.amount.toPlainString(), it.createdAt.toString(), it.category).joinToString(",")
        }
        return if (rows.isBlank()) "$header\n" else "$header\n$rows\n"
    }

    fun exportJson(): String {
        val array = JSONArray()
        _entries.value.forEach {
            array.put(
                JSONObject()
                    .put("id", it.id)
                    .put("title", it.title)
                    .put("amount", it.amount.toPlainString())
                    .put("createdAt", it.createdAt.toString())
                    .put("category", it.category)
            )
        }
        return array.toString(2)
    }

    fun replaceAll(entries: List<Entry>) {
        _entries.value = entries
    }

    fun currentMonthExpenseTotal(now: LocalDate = LocalDate.now()): BigDecimal {
        val zone = ZoneId.systemDefault()
        return _entries.value
            .asSequence()
            .filter { it.amount < BigDecimal.ZERO }
            .filter {
                val entryDate = it.createdAt.atZone(zone).toLocalDate()
                entryDate.year == now.year && entryDate.month == now.month
            }
            .fold(BigDecimal.ZERO) { acc, entry -> acc + entry.amount.abs() }
    }

    fun suggestBudgets(now: LocalDate = LocalDate.now()): List<Suggestion> {
        return BudgetIntelligenceEngine.buildDrafts(_entries.value, now).map {
            Suggestion(
                category = it.category,
                averageSpend = it.baseline,
                suggestedBudget = it.suggestedBudget,
                trend = it.trend,
            )
        }
    }

    fun detectOverspend(now: LocalDate = LocalDate.now()): List<Alert> {
        val drafts = BudgetIntelligenceEngine.buildDrafts(_entries.value, now)
        return BudgetIntelligenceEngine.forecastOverspend(_entries.value, drafts, now).map {
            Alert(
                category = it.category,
                spent = it.currentSpent,
                budget = it.budget,
                ratio = it.riskScore,
                danger = it.riskScore >= BigDecimal.ONE,
            )
        }
    }

    private fun parseCsvLine(line: String): List<String> {
        val out = mutableListOf<String>()
        val current = StringBuilder()
        var inQuotes = false
        var i = 0

        while (i < line.length) {
            val c = line[i]
            when {
                c == '"' && inQuotes && i + 1 < line.length && line[i + 1] == '"' -> {
                    current.append('"')
                    i += 1
                }
                c == '"' -> inQuotes = !inQuotes
                c == ',' && !inQuotes -> {
                    out += current.toString()
                    current.clear()
                }
                else -> current.append(c)
            }
            i += 1
        }

        out += current.toString()
        return out
    }
}
