package com.bkes994408.expensetracker.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

object ReplicaTokens {
    val cardRadius = 22.dp
    val cardBorder = Color(0xFFE4E8F4)
    val cardSurface = Color.White

    val rowRadius = 16.dp
    val rowBg = Color(0xFFF7F8FF)
    val rowBorder = Color(0xFFE8ECF8)

    val stateRadius = 14.dp
    val stateBg = Color(0xFFF6F8FF)
    val stateBorder = Color(0xFFE3E8F8)
    val stateTitle = Color(0xFF3B4770)
    val stateBody = Color(0xFF707A8D)
}

@Composable
fun ReplicaSectionCard(
    title: String,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    content: @Composable () -> Unit,
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .border(1.dp, ReplicaTokens.cardBorder, RoundedCornerShape(ReplicaTokens.cardRadius)),
        shape = RoundedCornerShape(ReplicaTokens.cardRadius),
        colors = CardDefaults.cardColors(containerColor = ReplicaTokens.cardSurface),
        elevation = CardDefaults.cardElevation(defaultElevation = 5.dp),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
            subtitle?.let {
                Text(it, style = MaterialTheme.typography.bodySmall, color = Color(0xFF6E7789))
            }
            content()
        }
    }
}

@Composable
fun ReplicaListRow(
    title: String,
    subtitle: String? = null,
    trailing: String? = null,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(ReplicaTokens.rowBg, RoundedCornerShape(ReplicaTokens.rowRadius))
            .border(1.dp, ReplicaTokens.rowBorder, RoundedCornerShape(ReplicaTokens.rowRadius))
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            subtitle?.let {
                Text(
                    text = it,
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFF727C90),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        trailing?.let {
            Text(it, style = MaterialTheme.typography.labelLarge, color = Color(0xFF4A5680), fontWeight = FontWeight.Medium)
        }
    }
}

@Composable
fun ReplicaStateBox(title: String, message: String, maxLines: Int = 3) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(ReplicaTokens.stateBg, RoundedCornerShape(ReplicaTokens.stateRadius))
            .border(1.dp, ReplicaTokens.stateBorder, RoundedCornerShape(ReplicaTokens.stateRadius))
            .padding(horizontal = 14.dp, vertical = 16.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(title, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold, color = ReplicaTokens.stateTitle)
            Text(
                text = message,
                style = MaterialTheme.typography.bodySmall,
                color = ReplicaTokens.stateBody,
                maxLines = maxLines,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
fun ReplicaEdgeStates(
    loadingMessage: String,
    emptyMessage: String,
    errorMessage: String,
    longTextMessage: String,
    denseContentHint: String,
) {
    ReplicaStateBox(title = "Loading", message = loadingMessage)
    ReplicaStateBox(title = "Empty", message = emptyMessage)
    ReplicaStateBox(title = "Error", message = errorMessage)
    ReplicaStateBox(title = "Long text", message = longTextMessage, maxLines = 4)
    ReplicaStateBox(title = "Dense content", message = denseContentHint)
}
