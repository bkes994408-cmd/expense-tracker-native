package com.bkes994408.expensetracker.security

import org.junit.Assert.assertEquals
import org.junit.Test

class LogRedactorTest {
    @Test
    fun maskEmail_masksLocalPart() {
        assertEquals("d***@example.com", LogRedactor.maskEmail("demo@example.com"))
        assertEquals("***", LogRedactor.maskEmail("invalid"))
    }

    @Test
    fun maskToken_masksMiddleSection() {
        assertEquals("abc***456", LogRedactor.maskToken("abcdef123456"))
        assertEquals("***", LogRedactor.maskToken("short"))
    }

    @Test
    fun redact_replacesSensitiveValues() {
        val raw = "auth success for demo@example.com token=abcdef123456"
        val redacted = LogRedactor.redact(raw, email = "demo@example.com", token = "abcdef123456")

        assertEquals("auth success for d***@example.com token=abc***456", redacted)
    }
}
