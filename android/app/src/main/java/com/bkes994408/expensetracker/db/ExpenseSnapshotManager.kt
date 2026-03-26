package com.bkes994408.expensetracker.db

import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

class ExpenseSnapshotManager(
    private val ledger: ExpenseLedger,
) {
    fun createSnapshot(): String {
        val payload = JSONObject()
            .put("version", 1)
            .put("createdAt", Instant.now().toString())
            .put("entries", JSONArray(ledger.exportJson()))
        return payload.toString(2)
    }

    fun restoreSnapshot(raw: String): Boolean {
        val root = runCatching { JSONObject(raw) }.getOrNull() ?: return false
        val entriesArray = root.optJSONArray("entries") ?: return false

        val restored = mutableListOf<ExpenseLedger.Entry>()
        for (index in 0 until entriesArray.length()) {
            val item = entriesArray.optJSONObject(index) ?: continue
            val title = item.optString("title").trim()
            val amount = item.optString("amount").toBigDecimalOrNull() ?: continue
            val createdAt = runCatching { Instant.parse(item.optString("createdAt")) }.getOrElse { Instant.now() }
            val category = item.optString("category", "未分類").ifBlank { "未分類" }
            if (title.isBlank()) continue
            restored += ExpenseLedger.Entry(title = title, amount = amount, createdAt = createdAt, category = category)
        }

        ledger.replaceAll(restored)
        return true
    }
}
