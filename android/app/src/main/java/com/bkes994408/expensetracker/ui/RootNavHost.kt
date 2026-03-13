package com.bkes994408.expensetracker.ui

import android.app.Activity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.bkes994408.expensetracker.data.ExpenseRepositoryImpl
import com.bkes994408.expensetracker.data.FileExpenseStore
import com.bkes994408.expensetracker.pro.GooglePlayBillingClient
import com.bkes994408.expensetracker.pro.GooglePlayBillingProPurchaseService
import com.bkes994408.expensetracker.pro.ProEntitlementStore

private object Routes {
    const val Home = "home"
    const val Settings = "settings"
}

@Composable
fun RootNavHost() {
    val navController = rememberNavController()
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

    NavHost(navController = navController, startDestination = Routes.Home) {
        composable(Routes.Home) {
            HomeScreen(
                onOpenSettings = { navController.navigate(Routes.Settings) },
                proEntitlementStore = proEntitlementStore,
                expenseRepository = expenseRepository,
            )
        }
        composable(Routes.Settings) {
            SettingsScreen(proEntitlementStore = proEntitlementStore)
        }
    }
}
