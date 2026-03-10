package com.bkes994408.expensetracker.telemetry

import android.os.SystemClock
import android.util.Log

enum class AnalyticsEvent {
    APP_LAUNCHED,
    APP_STARTUP_MEASURED,
    EXPENSE_ADDED,
    EXPENSE_ADD_INVALID,
    UNCAUGHT_EXCEPTION,
}

interface AnalyticsService {
    fun track(event: AnalyticsEvent, metadata: Map<String, String> = emptyMap())
}

interface CrashReporter {
    fun install()
    fun record(throwable: Throwable, fatal: Boolean, metadata: Map<String, String> = emptyMap())
}

class LogcatAnalyticsService : AnalyticsService {
    override fun track(event: AnalyticsEvent, metadata: Map<String, String>) {
        Log.i("ExpenseTelemetry", "event=${event.name} metadata=$metadata")
    }
}

class LogcatCrashReporter : CrashReporter {
    private val previousHandler = Thread.getDefaultUncaughtExceptionHandler()

    override fun install() {
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            Telemetry.record(throwable, fatal = true, metadata = mapOf("thread" to thread.name))
            previousHandler?.uncaughtException(thread, throwable)
        }
    }

    override fun record(throwable: Throwable, fatal: Boolean, metadata: Map<String, String>) {
        Log.e("ExpenseTelemetry", "fatal=$fatal metadata=$metadata", throwable)
    }
}

object Telemetry {
    private val appStartElapsedRealtimeMs = SystemClock.elapsedRealtime()
    private val analytics: AnalyticsService by lazy { LogcatAnalyticsService() }
    private val crashReporter: CrashReporter by lazy { LogcatCrashReporter() }

    fun install() {
        crashReporter.install()
        track(AnalyticsEvent.APP_LAUNCHED)
    }

    fun track(event: AnalyticsEvent, metadata: Map<String, String> = emptyMap()) {
        analytics.track(event, metadata)
    }

    fun record(throwable: Throwable, fatal: Boolean = false, metadata: Map<String, String> = emptyMap()) {
        if (fatal) {
            track(AnalyticsEvent.UNCAUGHT_EXCEPTION, metadata)
        }
        crashReporter.record(throwable, fatal, metadata)
    }

    fun markFirstFrameDrawn() {
        val elapsedMs = SystemClock.elapsedRealtime() - appStartElapsedRealtimeMs
        track(AnalyticsEvent.APP_STARTUP_MEASURED, mapOf("elapsedMs" to elapsedMs.toString()))
    }
}
