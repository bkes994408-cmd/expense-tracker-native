package com.bkes994408.expensetracker

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.core.view.doOnPreDraw
import com.bkes994408.expensetracker.telemetry.Telemetry
import com.bkes994408.expensetracker.ui.RootNavHost

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.decorView.doOnPreDraw {
            Telemetry.markFirstFrameDrawn()
        }
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    RootNavHost()
                }
            }
        }
    }
}
