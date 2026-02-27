package com.bkes994408.expensetracker.ui

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController

private object Routes {
    const val Home = "home"
    const val Settings = "settings"
}

@Composable
fun RootNavHost() {
    val navController = rememberNavController()

    NavHost(navController = navController, startDestination = Routes.Home) {
        composable(Routes.Home) {
            HomeScreen(onOpenSettings = { navController.navigate(Routes.Settings) })
        }
        composable(Routes.Settings) {
            SettingsScreen()
        }
    }
}
