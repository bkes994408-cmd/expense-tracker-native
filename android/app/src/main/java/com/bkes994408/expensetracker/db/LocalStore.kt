package com.bkes994408.expensetracker.db

import android.content.Context
import androidx.room.Room
import com.bkes994408.expensetracker.category.AppDatabase
import com.bkes994408.expensetracker.category.CategoryRepository
import com.bkes994408.expensetracker.category.CategoryRepositoryImpl

class LocalStore private constructor(context: Context) {
    private val database: AppDatabase = Room.databaseBuilder(
        context.applicationContext,
        AppDatabase::class.java,
        "expense-tracker.db",
    ).build()

    val categoryRepository: CategoryRepository = CategoryRepositoryImpl(database.categoryDao())

    companion object {
        @Volatile
        private var instance: LocalStore? = null

        fun getInstance(context: Context): LocalStore {
            return instance ?: synchronized(this) {
                instance ?: LocalStore(context).also { instance = it }
            }
        }
    }
}
