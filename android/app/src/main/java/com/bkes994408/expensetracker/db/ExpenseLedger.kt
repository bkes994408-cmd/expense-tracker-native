package com.bkes994408.expensetracker.db

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

class ExpenseLedger {
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

    fun addExpense(title: String, amount: BigDecimal, category: String = "未分類") {
        if (title.isBlank() || amount == BigDecimal.ZERO) return
        _entries.value = _entries.value + Entry(title = title.trim(), amount = amount, category = category)
    }

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

    fun currentMonthExpenseTotal(now: LocalDate = LocalDate.now()): BigDecimal {
        val zone = ZoneId.systemDefault()
        return _entries.value
            .asSequence()
            .filter { it.amount < BigDecimal.ZERO }
            .filter { LocalDate.ofInstant(it.createdAt, zone).year == now.year && LocalDate.ofInstant(it.createdAt, zone).month == now.month }
            .fold(BigDecimal.ZERO) { acc, entry -> acc + entry.amount.abs() }
    }

    fun suggestBudgets(now: LocalDate = LocalDate.now()): List<Suggestion> {
        val zone = ZoneId.systemDefault()
        val currentMonthStart = now.withDayOfMonth(1)
        val lookbackStart = currentMonthStart.minusMonths(3)

        val grouped = _entries.value
            .filter { it.amount < BigDecimal.ZERO }
            .filter {
                val date = LocalDate.ofInstant(it.createdAt, zone)
                !date.isBefore(lookbackStart) && date.isBefore(currentMonthStart)
            }
            .groupBy { it.category }

        return grouped.map { (category, values) ->
            val total = values.fold(BigDecimal.ZERO) { acc, entry -> acc + entry.amount.abs() }
            val average = if (values.isEmpty()) BigDecimal.ZERO else total.divide(BigDecimal(values.size), 2, RoundingMode.HALF_UP)
            val suggestion = average.multiply(BigDecimal("1.10")).setScale(2, RoundingMode.HALF_UP).max(BigDecimal("500"))
            Suggestion(category, average, suggestion)
        }.sortedByDescending { it.suggestedBudget }
    }

    fun detectOverspend(now: LocalDate = LocalDate.now()): List<Alert> {
        val zone = ZoneId.systemDefault()
        val spentByCategory = _entries.value
            .filter { it.amount < BigDecimal.ZERO }
            .filter {
                val date = LocalDate.ofInstant(it.createdAt, zone)
                date.year == now.year && date.month == now.month
            }
            .groupBy { it.category }
            .mapValues { (_, values) -> values.fold(BigDecimal.ZERO) { acc, e -> acc + e.amount.abs() } }

        return suggestBudgets(now).mapNotNull { suggestion ->
            val spent = spentByCategory[suggestion.category] ?: BigDecimal.ZERO
            if (suggestion.suggestedBudget <= BigDecimal.ZERO) return@mapNotNull null
            val ratio = spent.divide(suggestion.suggestedBudget, 4, RoundingMode.HALF_UP)
            when {
                ratio >= BigDecimal.ONE -> Alert(suggestion.category, spent, suggestion.suggestedBudget, ratio, danger = true)
                ratio >= BigDecimal("0.8") -> Alert(suggestion.category, spent, suggestion.suggestedBudget, ratio, danger = false)
                else -> null
            }
        }.sortedByDescending { it.ratio }
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
