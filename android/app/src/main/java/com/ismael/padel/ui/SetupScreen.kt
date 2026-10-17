package com.ismael.padel.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ismael.padel.AppState
import com.ismael.padel.Screen

/** Parejas, jugadores, saque inicial y formato. Lo escrito se aplica al momento. */
@Composable
fun SetupScreen(state: AppState) {
    val cfg = state.cfg
    val match = state.match
    val scroll = rememberScrollState()

    Column(
        Modifier.fillMaxSize().background(P.bg).verticalScroll(scroll).padding(16.dp)
    ) {
        Text(
            "🎾  Marcador de Pádel",
            color = P.txt, fontWeight = FontWeight.ExtraBold,
            fontSize = with(LocalDensity.current) { 24.dp.toSp() }
        )
        Spacer(Modifier.height(4.dp))
        Help("Configura el partido. Puedes dejarlo todo como está y empezar.")
        Spacer(Modifier.height(14.dp))

        Card("Parejas") {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Field("Pareja A", cfg.names[0], { v ->
                    state.updateCfg { it.copy(names = listOf(v, it.names[1])) }
                }, Modifier.weight(1f))
                Field("Pareja B", cfg.names[1], { v ->
                    state.updateCfg { it.copy(names = listOf(it.names[0], v)) }
                }, Modifier.weight(1f))
            }
            Spacer(Modifier.height(10.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Field("Jugador 1 (A)", cfg.players[0][0], { v ->
                    state.updateCfg { it.copy(players = listOf(listOf(v, it.players[0][1]), it.players[1])) }
                }, Modifier.weight(1f))
                Field("Jugador 2 (A)", cfg.players[0][1], { v ->
                    state.updateCfg { it.copy(players = listOf(listOf(it.players[0][0], v), it.players[1])) }
                }, Modifier.weight(1f))
            }
            Spacer(Modifier.height(10.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Field("Jugador 3 (B)", cfg.players[1][0], { v ->
                    state.updateCfg { it.copy(players = listOf(it.players[0], listOf(v, it.players[1][1]))) }
                }, Modifier.weight(1f))
                Field("Jugador 4 (B)", cfg.players[1][1], { v ->
                    state.updateCfg { it.copy(players = listOf(it.players[0], listOf(it.players[1][0], v))) }
                }, Modifier.weight(1f))
            }
        }

        Card("Saque inicial") {
            Help("El saque va rotando: A1 → B1 → A2 → B2 y vuelta a empezar.")
            Spacer(Modifier.height(10.dp))
            val opciones = listOf(
                cfg.players[0][0] to (0 to 0),
                cfg.players[0][1] to (0 to 1),
                cfg.players[1][0] to (1 to 0),
                cfg.players[1][1] to (1 to 1)
            )
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                opciones.chunked(2).forEach { fila ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        fila.forEach { (nombre, pareja) ->
                            val sel = cfg.firstServeTeam == pareja.first && cfg.firstServePlayer == pareja.second
                            PickButton(nombre, sel, Modifier.weight(1f)) {
                                state.updateCfg {
                                    it.copy(firstServeTeam = pareja.first, firstServePlayer = pareja.second)
                                }
                            }
                        }
                    }
                }
            }
        }

        Card("Formato") {
            Segmented(
                options = listOf("1 set" to 1, "Al mejor de 3" to 3, "Al mejor de 5" to 5),
                selected = cfg.bestOf,
                onPick = { v -> state.updateCfg { it.copy(bestOf = v as Int) } }
            )
            Spacer(Modifier.height(8.dp))
            SwitchRow(
                "Punto de oro",
                "Con 40-40 el siguiente punto decide el juego. Sin punto de oro se juega con ventajas.",
                cfg.golden
            ) { v -> state.updateCfg { it.copy(golden = v) } }
            SwitchRow(
                "Tie-break a 6-6",
                "Desactivado, el set se gana por diferencia de 2 juegos.",
                cfg.tiebreak
            ) { v -> state.updateCfg { it.copy(tiebreak = v) } }
            SwitchRow(
                "Super tie-break en el set decisivo",
                "El último set se juega a 10 puntos en lugar de a juegos.",
                cfg.superTb
            ) { v -> state.updateCfg { it.copy(superTb = v) } }
        }

        BigButton("Empezar partido", primary = true) { state.startMatch() }
        if (match.startedAt > 0L && !match.finished) {
            BigButton("Volver al partido en curso") {
                state.screen = Screen.MATCH
                state.showToast("Nombres actualizados")
            }
        }
        BigButton("Ajustes de sonido y mando ⚙") { state.screen = Screen.SETTINGS }
        Spacer(Modifier.height(24.dp))
    }
}
