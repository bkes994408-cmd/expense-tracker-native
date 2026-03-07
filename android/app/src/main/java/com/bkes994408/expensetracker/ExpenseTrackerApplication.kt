package com.bkes994408.expensetracker

import android.app.Application
import com.bkes994408.expensetracker.telemetry.Telemetry

class ExpenseTrackerApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Telemetry.install()
    }
}
