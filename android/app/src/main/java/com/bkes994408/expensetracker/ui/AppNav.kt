package com.bkes994408.expensetracker.ui

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable

private object Routes {
    const val Home = "home"
    const val Add = "add"
}

@Composable
fun AppNav(
    navController: NavHostController,
    viewModel: AppViewModel,
) {
    NavHost(navController = navController, startDestination = Routes.Home) {
        composable(Routes.Home) {
            HomeScreen(
                viewModel = viewModel,
                onAdd = { navController.navigate(Routes.Add) },
            )
        }
        composable(Routes.Add) {
            AddTransactionScreen(
                onBack = { navController.popBackStack() },
                onSave = { amountCents, note, occurredAt ->
                    viewModel.add(amountCents, note, occurredAt)
                    navController.popBackStack()
                }
            )
        }
    }
}
