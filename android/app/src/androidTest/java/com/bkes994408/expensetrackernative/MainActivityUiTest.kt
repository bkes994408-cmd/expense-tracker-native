package com.bkes994408.expensetrackernative

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import org.junit.Rule
import org.junit.Test

class MainActivityUiTest {
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun appLaunch_displaysBasicContent() {
        composeTestRule.onNodeWithText("Expense Tracker Native").assertIsDisplayed()
        composeTestRule.onNodeWithText("MVP-0 Android skeleton is buildable").assertIsDisplayed()
    }
}
