package com.ismael.padel.ui

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/** Los mismos colores que la versión web. */
object P {
    val bg = Color(0xFF0B1220)
    val panel = Color(0xFF141D31)
    val panel2 = Color(0xFF1B2743)
    val line = Color(0xFF2A3752)
    val txt = Color(0xFFEEF3FF)
    val dim = Color(0xFF93A2C4)
    val teamA = Color(0xFF36D399)   // verde
    val teamB = Color(0xFFFBBF24)   // amarillo
    val danger = Color(0xFFF87171)
    val ball = Color(0xFFCBE92F)

    fun team(i: Int) = if (i == 0) teamA else teamB

    val radius: Dp = 18.dp
}
