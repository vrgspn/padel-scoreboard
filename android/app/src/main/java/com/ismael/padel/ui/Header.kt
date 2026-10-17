package com.ismael.padel.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.ismael.padel.AppState
import com.ismael.padel.Rules
import com.ismael.padel.Screen

@Composable
fun Header(state: AppState) {
    val match = state.match
    val cfg = state.cfg

    Row(
        Modifier.fillMaxWidth().padding(horizontal = 10.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // izquierda: sets y formato
        Row(
            Modifier.weight(1f),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Chip("Sets ${match.setsWon[0]} - ${match.setsWon[1]}")
            if (match.tiebreak) Chip(if (match.tbTarget == 10) "Super tie-break" else "Tie-break")
        }

        // centro: acciones del partido
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
            IconBtn("↶", enabled = state.canUndo) { state.undo() }
            IconBtn("↷", enabled = state.canRedo) { state.redo() }
            IconBtn("✚", highlighted = true) { state.screen = Screen.SETUP }
        }

        // derecha: voz y ajustes
        Row(
            Modifier.weight(1f),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Spacer(Modifier.weight(1f))
            IconBtn(if (cfg.voice) "🔊" else "🔇", active = cfg.voice) { state.toggleVoice() }
            IconBtn("⚙") { state.screen = Screen.SETTINGS }
        }
    }
}

@Composable
fun Chip(text: String) {
    Box(
        Modifier.clip(RoundedCornerShape(50)).background(P.panel)
            .border(1.dp, P.line, RoundedCornerShape(50))
            .padding(horizontal = 10.dp, vertical = 5.dp)
    ) {
        Text(text, color = P.txt, fontSize = with(LocalDensity.current) { 13.dp.toSp() }, maxLines = 1)
    }
}

@Composable
fun IconBtn(
    label: String,
    enabled: Boolean = true,
    active: Boolean = false,
    highlighted: Boolean = false,
    onClick: () -> Unit
) {
    val bg = when {
        active -> Color(0xFF12251F)
        highlighted -> P.panel2
        else -> P.panel
    }
    val border = when {
        active -> P.teamA.copy(alpha = 0.5f)
        highlighted -> Color(0xFF3F5A86)
        else -> P.line
    }
    Box(
        Modifier.size(46.dp).alpha(if (enabled) 1f else 0.32f)
            .clip(RoundedCornerShape(13.dp)).background(bg)
            .border(1.dp, border, RoundedCornerShape(13.dp))
            .clickable(enabled = enabled) { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Text(
            label,
            color = if (active) P.teamA else if (highlighted) P.txt else P.dim,
            fontSize = with(LocalDensity.current) { 19.dp.toSp() }
        )
    }
}

/** Aviso grande centrado: cambio de lado, tie-break, set o partido. */
@Composable
fun BannerOverlay(state: AppState) {
    val banner = state.banner ?: return
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        Column(
            Modifier.clip(RoundedCornerShape(20.dp)).background(Color(0xFF0F1A2E))
                .border(1.dp, P.line, RoundedCornerShape(20.dp))
                .padding(horizontal = 30.dp, vertical = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                banner.big, color = P.txt, fontWeight = FontWeight.ExtraBold,
                fontSize = with(LocalDensity.current) { 28.dp.toSp() }
            )
            if (banner.sub.isNotEmpty()) {
                Spacer(Modifier.height(6.dp))
                Text(banner.sub, color = P.dim, fontSize = with(LocalDensity.current) { 14.dp.toSp() })
            }
        }
    }
}

/** Mensaje breve en la parte inferior. */
@Composable
fun ToastOverlay(state: AppState) {
    val text = state.toast ?: return
    Box(
        Modifier.clip(RoundedCornerShape(50)).background(Color(0xFF0F1A2E))
            .border(1.dp, P.line, RoundedCornerShape(50))
            .padding(horizontal = 18.dp, vertical = 9.dp)
    ) {
        Text(text, color = P.txt, fontSize = with(LocalDensity.current) { 14.dp.toSp() }, maxLines = 1)
    }
}

/** Aviso del mando de un botón: cuántas pulsaciones llevas y qué va a pasar. */
@Composable
fun BurstOverlay(state: AppState) {
    if (state.burstCount <= 0) return
    Column(
        Modifier.clip(RoundedCornerShape(18.dp)).background(Color(0xFF0F1A2E))
            .border(1.dp, P.line, RoundedCornerShape(18.dp))
            .padding(horizontal = 22.dp, vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            repeat(3) { i ->
                Box(
                    Modifier.size(18.dp).clip(RoundedCornerShape(50))
                        .background(if (i < state.burstCount) P.teamA else Color(0xFF334155))
                )
            }
        }
        Spacer(Modifier.height(10.dp))
        Text(
            state.burstText(state.burstCount),
            color = P.txt,
            fontWeight = FontWeight.SemiBold,
            fontSize = with(LocalDensity.current) { 15.dp.toSp() }
        )
        Spacer(Modifier.height(10.dp))
        BurstBar(state)
    }
}

@Composable
private fun BurstBar(state: AppState) {
    val progress = countdownProgress(state.burstId, state.cfg.burstWindowMs)
    Box(
        Modifier.width(190.dp).height(5.dp).clip(RoundedCornerShape(50)).background(Color(0xFF24324D))
    ) {
        Box(
            Modifier.fillMaxWidth(progress.coerceIn(0.001f, 1f)).height(5.dp)
                .clip(RoundedCornerShape(50)).background(P.teamA)
        )
    }
}

/** Va de 1 a 0 durante la espera entre pulsaciones del mando. */
@Composable
private fun countdownProgress(key: Long, windowMs: Long): Float {
    val anim = remember { Animatable(1f) }
    LaunchedEffect(key) {
        anim.snapTo(1f)
        anim.animateTo(0f, tween(durationMillis = windowMs.toInt(), easing = LinearEasing))
    }
    return anim.value
}

@Composable
fun SectionTitle(text: String) {
    Box(Modifier.heightIn(min = 22.dp)) {
        Text(
            text.uppercase(), color = P.dim, fontWeight = FontWeight.Bold,
            fontSize = with(LocalDensity.current) { 12.dp.toSp() },
            letterSpacing = with(LocalDensity.current) { 1.4.dp.toSp() }
        )
    }
}
