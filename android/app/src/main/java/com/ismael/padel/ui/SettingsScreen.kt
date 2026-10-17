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

@Composable
fun SettingsScreen(state: AppState) {
    val cfg = state.cfg
    val scroll = rememberScrollState()

    Column(Modifier.fillMaxSize().background(P.bg).verticalScroll(scroll).padding(16.dp)) {
        Text(
            "⚙  Ajustes",
            color = P.txt, fontWeight = FontWeight.ExtraBold,
            fontSize = with(LocalDensity.current) { 24.dp.toSp() }
        )
        Spacer(Modifier.height(4.dp))
        Help("Sonido, mando a distancia, pantalla y partido.")
        Spacer(Modifier.height(14.dp))

        Card("Sonido") {
            SwitchRow(
                "Cantar el marcador",
                "Dice el tanteo tras cada punto y quién gana cada juego, set y partido. Siempre empezando por quien saca, como en la pista.",
                cfg.voice
            ) { v -> state.updateCfg { it.copy(voice = v) } }
            SwitchRow(
                "Decir quién saca",
                "Añade «saca Ismael» después del tanteo.",
                cfg.voiceServer
            ) { v -> state.updateCfg { it.copy(voiceServer = v) } }
            SwitchRow(
                "Decir desde qué lado saca",
                "Añade «desde la derecha» o «desde la izquierda», según toque cuadro de derecha o de revés.",
                cfg.voiceCourtSide
            ) { v -> state.updateCfg { it.copy(voiceCourtSide = v) } }
            SwitchRow(
                "Avisar del cambio de lado",
                "Dice «cambio de lado» cuando toca cambiar de pista.",
                cfg.voiceSwitch
            ) { v -> state.updateCfg { it.copy(voiceSwitch = v) } }
            SwitchRow(
                "Vibrar al apuntar",
                "Confirmación táctil al sumar cada punto.",
                cfg.vibrate
            ) { v -> state.updateCfg { it.copy(vibrate = v) } }

            Spacer(Modifier.height(12.dp))
            Text("Velocidad de la voz", color = P.dim, fontSize = with(LocalDensity.current) { 13.dp.toSp() })
            Spacer(Modifier.height(6.dp))
            Segmented(
                options = listOf("Lenta" to 0.9f, "Normal" to 1.05f, "Rápida" to 1.3f),
                selected = cfg.voiceRate,
                onPick = { v -> state.updateCfg { it.copy(voiceRate = v as Float) } }
            )
            Spacer(Modifier.height(10.dp))
            SmallButton("▶  Probar voz", Modifier.fillMaxWidth()) { state.speakTest() }
        }

        Card("Mando de disparo (pulsador)") {
            SwitchRow(
                "Usar las teclas de volumen",
                "La app se queda las teclas de volumen del móvil y de tu pulsador Bluetooth, así que ya no suben ni bajan el sonido mientras juegas.",
                cfg.volumeKeys
            ) { v -> state.updateCfg { it.copy(volumeKeys = v) } }
            SwitchRow(
                "Modo un solo botón",
                "Para pulsadores con un único botón: 1 pulsación = punto para quien saca · 2 pulsaciones = punto para quien resta · 3 pulsaciones = deshacer.",
                cfg.oneButton
            ) { v -> state.updateCfg { it.copy(oneButton = v) } }

            Spacer(Modifier.height(12.dp))
            Text("Espera entre pulsaciones", color = P.dim, fontSize = with(LocalDensity.current) { 13.dp.toSp() })
            Spacer(Modifier.height(6.dp))
            Segmented(
                options = listOf("1,5 s" to 1500L, "3 s" to 3000L, "5 s" to 5000L, "8 s" to 8000L),
                selected = cfg.burstWindowMs,
                onPick = { v -> state.updateCfg { it.copy(burstWindowMs = v as Long) } }
            )
            Spacer(Modifier.height(8.dp))
            Help(
                "Tiempo que se espera otra pulsación antes de apuntar. Súbelo si tu pulsador tarda en responder; " +
                    "bájalo si quieres que el punto entre al instante. Con tres pulsaciones no se espera."
            )
            if (state.lastSignal.isNotEmpty()) {
                Spacer(Modifier.height(10.dp))
                Text(
                    "Última señal recibida: " + state.lastSignal,
                    color = P.teamA,
                    fontSize = with(LocalDensity.current) { 13.dp.toSp() }
                )
            }
            Spacer(Modifier.height(8.dp))
            Help(
                "Sin el modo un solo botón, bajar volumen suma punto a la pareja A y subir volumen a la pareja B. " +
                    "Un toque en cada mitad de la pantalla también suma punto."
            )
        }

        Card("Pantalla") {
            SwitchRow(
                "Mantener pantalla encendida",
                "Evita que se apague durante el partido.",
                cfg.keepAwake
            ) { v -> state.updateCfg { it.copy(keepAwake = v) } }
            SwitchRow(
                "Intercambiar lados automáticamente",
                "Al cambiar de lado en la pista, las parejas también cambian en el marcador.",
                cfg.autoSwap
            ) { v -> state.updateCfg { it.copy(autoSwap = v) } }
            SwitchRow(
                "Avisar del cambio de lado",
                "Muestra un cartel cuando toca cambiar.",
                cfg.sideAlert
            ) { v -> state.updateCfg { it.copy(sideAlert = v) } }
            Spacer(Modifier.height(12.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                SmallButton("⇄  Intercambiar lados", Modifier.weight(1f)) { state.swapSides() }
            }
        }

        BigButton("Volver al partido", primary = true) { state.screen = Screen.MATCH }
        BigButton("Editar parejas y formato") { state.screen = Screen.SETUP }
        BigButton("Reiniciar marcador a 0", danger = true) { state.resetScore(); state.screen = Screen.MATCH }
        Spacer(Modifier.height(24.dp))
    }
}
