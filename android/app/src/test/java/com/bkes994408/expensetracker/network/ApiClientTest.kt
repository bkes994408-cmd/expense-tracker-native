package com.bkes994408.expensetracker.network

import org.junit.Assert.assertEquals
import org.junit.Test

class ApiClientTest {
    @Test
    fun buildAuthAuditLog_redactsEmailAndToken() {
        val client = ApiClient()

        val out = client.buildAuthAuditLog(
            email = "demo@example.com",
            token = "abcdef123456",
            success = true,
        )

        assertEquals("auth success for d***@example.com token=abc***456", out)
    }
}
