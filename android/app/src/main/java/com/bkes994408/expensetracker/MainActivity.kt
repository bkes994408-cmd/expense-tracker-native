package com.bkes994408.expensetracker

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.rememberNavController
import androidx.room.Room
import com.bkes994408.expensetracker.data.db.AppDatabase
import com.bkes994408.expensetracker.data.repo.RoomTransactionRepository
import com.bkes994408.expensetracker.domain.AddTransactionUseCase
import com.bkes994408.expensetracker.domain.DeleteTransactionUseCase
import com.bkes994408.expensetracker.domain.ObserveTransactionsUseCase
import com.bkes994408.expensetracker.ui.AppNav
import com.bkes994408.expensetracker.ui.AppViewModel
import com.bkes994408.expensetracker.ui.AppViewModelFactory
import androidx.compose.material3.MaterialTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val db = Room.databaseBuilder(
            applicationContext,
            AppDatabase::class.java,
            "expense_tracker.db",
        ).build()

        val repository = RoomTransactionRepository(db.transactionDao())
        val observe = ObserveTransactionsUseCase(repository)
        val add = AddTransactionUseCase(repository)
        val delete = DeleteTransactionUseCase(repository)

        val factory = AppViewModelFactory(
            observeTransactions = observe,
            addTransaction = add,
            deleteTransaction = delete,
        )

        setContent {
            val navController = rememberNavController()
            val vm: AppViewModel = viewModel(factory = factory)

            MaterialTheme {
                AppNav(
                    navController = navController,
                    viewModel = vm,
                )
            }
        }
    }
}
