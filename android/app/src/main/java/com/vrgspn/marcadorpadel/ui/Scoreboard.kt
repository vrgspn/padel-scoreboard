package com.vrgspn.marcadorpadel.ui

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.keyframes
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.material3.Text
import com.vrgspn.marcadorpadel.AppState
import com.vrgspn.marcadorpadel.Match
import com.vrgspn.marcadorpadel.Rules
import kotlin.math.min

/** Pantalla del marcador: dos cuadros, uno por pareja. */
@Composable
fun MatchScreen(state: AppState) {
    val match = state.match

    Column(Modifier.fillMaxSize().background(P.bg)) {
        Header(state)

        BoxWithConstraints(Modifier.weight(1f).fillMaxWidth().padding(horizontal = 10.dp, vertical = 0.dp)) {
            val portrait = maxHeight > maxWidth
            val w = maxWidth
            val h = maxHeight

            // tamaños calculados como en la web: proporcionales a la pantalla
            val numberDp: Dp = if (portrait) min(h.value * 0.30f, w.value * 0.44f).dp
            else min(h.value * 0.52f, w.value * 0.30f).dp
            val nameDp: Dp = if (portrait) (w.value * 0.055f).coerceIn(22f, 40f).dp
            else (h.value * 0.065f).coerceIn(18f, 38f).dp
            val playerDp: Dp = if (portrait) (w.value * 0.055f).coerceIn(17f, 34f).dp
            else (h.value * 0.075f).coerceIn(16f, 34f).dp

            // el primer panel es el de la izquierda (o el de arriba en vertical)
            val order = if (match.swapped) listOf(1, 0) else listOf(0, 1)

            if (portrait) {
                Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    order.forEach { t ->
                        TeamPanel(
                            state, t, portrait = true,
                            rightSide = false,
                            numberDp = numberDp, nameDp = nameDp, playerDp = playerDp,
                            modifier = Modifier.weight(1f).fillMaxWidth()
                        )
                    }
                }
            } else {
                Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    order.forEachIndexed { index, t ->
                        TeamPanel(
                            state, t, portrait = false,
                            rightSide = index == 1,
                            numberDp = numberDp, nameDp = nameDp, playerDp = playerDp,
                            modifier = Modifier.weight(1f).fillMaxHeight()
                        )
                    }
                }
            }
        }
        Spacer(Modifier.height(10.dp))
    }
}

@Composable
private fun TeamPanel(
    state: AppState,
    team: Int,
    portrait: Boolean,
    rightSide: Boolean,
    numberDp: Dp,
    nameDp: Dp,
    playerDp: Dp,
    modifier: Modifier = Modifier
) {
    val match = state.match
    val cfg = state.cfg
    val color = P.team(team)
    val serving = Rules.serverOf(match, cfg)
    val isServingTeam = serving.first == team && !match.finished

    // destello: entra rápido y se apaga en 1,5 s, sumando luz (como el modo screen de la web)
    val glow = remember { Animatable(0f) }
    LaunchedEffect(state.flashId) {
        if (state.flashTeam == team && state.flashId != 0L) {
            glow.snapTo(0f)
            glow.animateTo(
                0f,
                keyframes {
                    durationMillis = 1500
                    0f at 0
                    1f at 270
                    0.75f at 825
                    0f at 1500
                }
            )
        }
    }

    Box(
        modifier
            .clip(RoundedCornerShape(P.radius))
            .background(P.panel)
            .border(
                width = 1.dp,
                color = if (isServingTeam) color.copy(alpha = 0.55f) else P.line,
                shape = RoundedCornerShape(P.radius)
            )
            .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
            .drawWithContent {
                drawContent()
                val a = glow.value
                if (a > 0.001f) {
                    drawRect(
                        brush = Brush.radialGradient(
                            0.0f to color,
                            0.42f to color.copy(alpha = 0.75f),
                            0.70f to color.copy(alpha = 0.30f),
                            0.88f to Color.Transparent,
                            center = center,
                            radius = size.maxDimension * 0.75f
                        ),
                        alpha = a,
                        blendMode = BlendMode.Screen
                    )
                }
            }
            .clickable { state.addPoint(team) }
    ) {
        val playerTop = @Composable {
            PlayerRow(
                name = cfg.players[team][0],
                serving = isServingTeam && serving.second == 0,
                sizeDp = playerDp,
                alignEnd = rightSide
            )
        }
        val playerBottom = @Composable {
            PlayerRow(
                name = cfg.players[team][1],
                serving = isServingTeam && serving.second == 1,
                sizeDp = playerDp,
                alignEnd = rightSide
            )
        }
        val scoreBlock = @Composable {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                AutoText(
                    text = cfg.names[team],
                    sizeDp = nameDp,
                    color = color,
                    weight = FontWeight.ExtraBold,
                    letterSpacingEm = 0.06f,
                    uppercase = true,
                    maxLines = 2
                )
                AutoText(
                    text = Rules.pointLabel(match, team),
                    sizeDp = if (Rules.pointLabel(match, team) == "AD") numberDp * 0.62f else numberDp,
                    color = P.txt,
                    weight = FontWeight.ExtraBold,
                    lineHeightFactor = 0.9f
                )
            }
        }

        if (portrait) {
            Row(Modifier.fillMaxSize()) {
                Column(
                    Modifier.weight(0.42f).fillMaxHeight().padding(start = 14.dp, end = 4.dp, top = 10.dp, bottom = 10.dp),
                    verticalArrangement = Arrangement.SpaceBetween
                ) {
                    playerTop()
                    playerBottom()
                    GamesRow(state, team)
                }
                Box(Modifier.weight(0.58f).fillMaxHeight(), contentAlignment = Alignment.Center) { scoreBlock() }
            }
        } else {
            Column(Modifier.fillMaxSize().padding(10.dp)) {
                playerTop()
                Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) { scoreBlock() }
                playerBottom()
                Spacer(Modifier.height(4.dp))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) { GamesRow(state, team) }
            }
        }

        // aviso de punto de juego / break / set / partido, en la esquina
        val stake = Rules.stake(match, team, cfg).ifEmpty {
            if (!match.tiebreak && cfg.golden && match.pts[0] == 3 && match.pts[1] == 3) "Punto de oro" else ""
        }
        if (stake.isNotEmpty()) {
            Box(
                Modifier.align(if (portrait) Alignment.TopEnd else Alignment.BottomEnd).padding(8.dp)
                    .clip(RoundedCornerShape(50))
                    .background(color.copy(alpha = 0.18f))
                    .border(1.dp, color.copy(alpha = 0.45f), RoundedCornerShape(50))
                    .padding(horizontal = 10.dp, vertical = 4.dp)
            ) {
                Text(
                    stake.uppercase(),
                    color = color,
                    fontSize = with(LocalDensity.current) { 12.dp.toSp() },
                    fontWeight = FontWeight.Bold,
                    maxLines = 1
                )
            }
        }
    }
}

@Composable
private fun PlayerRow(name: String, serving: Boolean, sizeDp: Dp, alignEnd: Boolean) {
    Row(
        Modifier.fillMaxWidth(),
        horizontalArrangement = if (alignEnd) Arrangement.End else Arrangement.Start,
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (!alignEnd && serving) {
            Ball(sizeDp * 0.72f)
            Spacer(Modifier.size(8.dp))
        }
        Text(
            text = name,
            color = if (serving) P.txt else P.dim,
            fontSize = with(LocalDensity.current) { sizeDp.toSp() },
            fontWeight = if (serving) FontWeight.Bold else FontWeight.SemiBold,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            textAlign = if (alignEnd) TextAlign.End else TextAlign.Start,
            modifier = Modifier.widthIn(max = 2000.dp)
        )
        if (alignEnd && serving) {
            Spacer(Modifier.size(8.dp))
            Ball(sizeDp * 0.72f)
        }
    }
}

@Composable
private fun Ball(size: Dp) {
    Box(
        Modifier.size(size).clip(CircleShape)
            .background(
                Brush.radialGradient(
                    colors = listOf(Color(0xFFEAFF79), P.ball, Color(0xFF9CBF16)),
                    radius = with(LocalDensity.current) { size.toPx() }
                )
            )
    )
}

@Composable
private fun GamesRow(state: AppState, team: Int) {
    val match: Match = state.match
    val color = P.team(team)
    Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
        match.sets.forEach { s ->
            GameBox(
                text = s.games(team).toString(),
                sup = if (s.hadTiebreak) s.tb(team).toString() else null,
                color = if (s.games(team) > s.games(1 - team)) P.txt else P.dim,
                background = P.panel2
            )
        }
        if (!match.finished) {
            GameBox(
                text = match.games[team].toString(),
                sup = null,
                color = color,
                background = color.copy(alpha = 0.18f)
            )
        }
    }
}

@Composable
private fun GameBox(text: String, sup: String?, color: Color, background: Color) {
    Box(
        Modifier.size(width = 34.dp, height = 34.dp).clip(RoundedCornerShape(9.dp)).background(background),
        contentAlignment = Alignment.Center
    ) {
        Row(verticalAlignment = Alignment.Top) {
            Text(
                text,
                color = color,
                fontSize = with(LocalDensity.current) { 18.dp.toSp() },
                fontWeight = FontWeight.Bold
            )
            if (sup != null) {
                Text(
                    sup,
                    color = P.dim,
                    fontSize = with(LocalDensity.current) { 10.dp.toSp() },
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

/** Texto que se adapta al tamaño pedido en dp (respetando el tamaño de letra del sistema). */
@Composable
fun AutoText(
    text: String,
    sizeDp: Dp,
    color: Color,
    weight: FontWeight = FontWeight.Normal,
    letterSpacingEm: Float = 0f,
    uppercase: Boolean = false,
    maxLines: Int = 1,
    lineHeightFactor: Float = 1.1f
) {
    val density = LocalDensity.current
    Text(
        text = if (uppercase) text.uppercase() else text,
        color = color,
        fontSize = with(density) { sizeDp.toSp() },
        lineHeight = with(density) { (sizeDp * lineHeightFactor).toSp() },
        fontWeight = weight,
        letterSpacing = with(density) { (sizeDp * letterSpacingEm).toSp() },
        maxLines = maxLines,
        overflow = TextOverflow.Ellipsis,
        textAlign = TextAlign.Center
    )
}
