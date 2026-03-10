package com.bkes994408.expensetracker.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.bkes994408.expensetracker.pro.ProEntitlementStore

private object Routes {
    const val Home = "home"
    const val Settings = "settings"
}

@Composable
fun RootNavHost() {
    val navController = rememberNavController()
    val context = LocalContext.current
    val proEntitlementStore = ProEntitlementStore(context)

    NavHost(navController = navController, startDestination = Routes.Home) {
        composable(Routes.Home) {
            HomeScreen(
                onOpenSettings = { navController.navigate(Routes.Settings) },
                proEntitlementStore = proEntitlementStore,
            )
        }
        composable(Routes.Settings) {
            SettingsScreen(proEntitlementStore = proEntitlementStore)
        }
    }
}
