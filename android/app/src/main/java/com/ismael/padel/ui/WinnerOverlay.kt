package com.ismael.padel.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.ismael.padel.AppState
import com.ismael.padel.Screen

/** Se muestra al acabar el partido, con el resultado y el tiempo jugado. */
@Composable
fun WinnerOverlay(state: AppState) {
    val match = state.match
    if (!match.finished || match.winner < 0) return

    Box(
        Modifier.fillMaxSize().background(Color(0xEE060A13)).padding(24.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
            Text("🏆", fontSize = with(LocalDensity.current) { 64.dp.toSp() })
            Spacer(Modifier.height(8.dp))
            Text(
                state.cfg.names[match.winner],
                color = P.txt, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center,
                fontSize = with(LocalDensity.current) { 32.dp.toSp() }
            )
            Spacer(Modifier.height(10.dp))
            Text(
                state.scoreLine(),
                color = P.dim, textAlign = TextAlign.Center,
                fontSize = with(LocalDensity.current) { 22.dp.toSp() }
            )
            Spacer(Modifier.height(6.dp))
            val mins = (match.elapsed / 60000L).toInt()
            Text(
                state.cfg.players[match.winner].joinToString(" y ") + if (mins > 0) " · $mins min" else "",
                color = P.dim, textAlign = TextAlign.Center,
                fontSize = with(LocalDensity.current) { 14.dp.toSp() }
            )
            Spacer(Modifier.height(20.dp))
            BigButton("Nuevo partido", primary = true) { state.setScreen(Screen.SETUP) }
            BigButton("Deshacer el último punto") { state.undo() }
        }
    }
}
