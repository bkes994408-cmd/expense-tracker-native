package com.bkes994408.expensetracker.network

import com.bkes994408.expensetracker.security.LogRedactor

class ApiClient {
    suspend fun ping(): Boolean = true

    fun buildAuthAuditLog(email: String, token: String, success: Boolean): String {
        val status = if (success) "success" else "failed"
        val raw = "auth $status for $email token=$token"
        return LogRedactor.redact(raw, email = email, token = token)
    }
}
