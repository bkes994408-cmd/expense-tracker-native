package com.bkes994408.expensetracker.ui

import android.app.Activity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import com.bkes994408.expensetracker.data.ExpenseRepositoryImpl
import com.bkes994408.expensetracker.data.FileExpenseStore
import com.bkes994408.expensetracker.db.LocalStore
import com.bkes994408.expensetracker.pro.GooglePlayBillingClient
import com.bkes994408.expensetracker.pro.GooglePlayBillingProPurchaseService
import com.bkes994408.expensetracker.pro.ProEntitlementStore

enum class MainTab {
    Dashboard,
    Transactions,
    Reports,
    Settings,
}

@Composable
fun RootNavHost() {
    val context = LocalContext.current

    val purchaseService = remember(context) {
        GooglePlayBillingProPurchaseService(
            billingClient = GooglePlayBillingClient(
                context = context.applicationContext,
                activityProvider = { context as? Activity },
            ),
        )
    }
    val proEntitlementStore = remember(context, purchaseService) { ProEntitlementStore(context, purchaseService) }
    val expenseRepository = remember(context) { ExpenseRepositoryImpl(FileExpenseStore(context)) }

    LaunchedEffect(expenseRepository) {
        runCatching { expenseRepository.syncFromCloud() }
    }

    val localStore = remember { LocalStore.getInstance(context) }
    val homeViewModel = remember { HomeViewModel(localStore.expenseLedger) }
    var selectedTab by remember { mutableStateOf(MainTab.Dashboard) }

    when (selectedTab) {
        MainTab.Settings -> SettingsScreen(
            proEntitlementStore = proEntitlementStore,
        )

        else -> HomeScreen(
            homeViewModel = homeViewModel,
            proEntitlementStore = proEntitlementStore,
            expenseRepository = expenseRepository,
            selectedTab = selectedTab,
            onTabSelected = { selectedTab = it },
            onFabClick = { selectedTab = MainTab.Transactions },
        )
    }
}
