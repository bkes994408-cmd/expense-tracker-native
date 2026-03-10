package com.bkes994408.expensetracker.security

object LogRedactor {
    fun maskEmail(email: String): String {
        val parts = email.split("@", limit = 2)
        if (parts.size != 2) return "***"
        val local = parts[0]
        val domain = parts[1]
        val prefix = local.firstOrNull()?.toString() ?: "*"
        return "${prefix}***@$domain"
    }

    fun maskToken(token: String): String {
        if (token.length <= 6) return "***"
        val prefix = token.take(3)
        val suffix = token.takeLast(3)
        return "${prefix}***${suffix}"
    }

    fun redact(message: String, email: String? = null, token: String? = null): String {
        var out = message
        if (!email.isNullOrBlank()) {
            out = out.replace(email, maskEmail(email))
        }
        if (!token.isNullOrBlank()) {
            out = out.replace(token, maskToken(token))
        }
        return out
    }
}
