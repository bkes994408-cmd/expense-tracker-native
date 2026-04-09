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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

val ReplicaCardRadius = 22.dp
val ReplicaCardBorder = Color(0xFFE4E8F4)
val ReplicaCardSurface = Color.White

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
            .border(1.dp, ReplicaCardBorder, RoundedCornerShape(ReplicaCardRadius)),
        shape = RoundedCornerShape(ReplicaCardRadius),
        colors = CardDefaults.cardColors(containerColor = ReplicaCardSurface),
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
            .background(Color(0xFFF7F8FF), RoundedCornerShape(16.dp))
            .border(1.dp, Color(0xFFE8ECF8), RoundedCornerShape(16.dp))
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            subtitle?.let {
                Text(it, style = MaterialTheme.typography.bodySmall, color = Color(0xFF727C90))
            }
        }
        trailing?.let {
            Text(it, style = MaterialTheme.typography.labelLarge, color = Color(0xFF4A5680), fontWeight = FontWeight.Medium)
        }
    }
}

@Composable
fun ReplicaStateBox(title: String, message: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color(0xFFF6F8FF), RoundedCornerShape(14.dp))
            .border(1.dp, Color(0xFFE3E8F8), RoundedCornerShape(14.dp))
            .padding(horizontal = 14.dp, vertical = 16.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(title, style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold, color = Color(0xFF3B4770))
            Text(message, style = MaterialTheme.typography.bodySmall, color = Color(0xFF707A8D))
        }
    }
}
