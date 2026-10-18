package com.vrgspn.marcadorpadel.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp

/** Tarjeta gris con título, como las secciones de la versión web. */
@Composable
fun Card(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxWidth().padding(bottom = 12.dp)
            .clip(RoundedCornerShape(16.dp)).background(P.panel)
            .border(1.dp, P.line, RoundedCornerShape(16.dp))
            .padding(14.dp)
    ) {
        SectionTitle(title)
        Spacer(Modifier.height(10.dp))
        content()
    }
}

/** Fila con interruptor; se puede pulsar en toda la fila. */
@Composable
fun SwitchRow(title: String, subtitle: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable { onChange(!checked) }.padding(vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f).padding(end = 12.dp)) {
            Text(
                title, color = P.txt, fontWeight = FontWeight.SemiBold,
                fontSize = with(LocalDensity.current) { 15.dp.toSp() }
            )
            if (subtitle.isNotEmpty()) {
                Spacer(Modifier.height(3.dp))
                Text(
                    subtitle, color = P.dim,
                    fontSize = with(LocalDensity.current) { 12.dp.toSp() },
                    lineHeight = with(LocalDensity.current) { 16.dp.toSp() }
                )
            }
        }
        Switch(
            checked = checked,
            onCheckedChange = { onChange(it) },
            colors = SwitchDefaults.colors(
                checkedThumbColor = P.teamA,
                checkedTrackColor = Color(0xFF14532D),
                uncheckedThumbColor = Color(0xFF64748B),
                uncheckedTrackColor = Color(0xFF2A3752)
            )
        )
    }
    Divider()
}

@Composable
fun Divider() {
    Box(Modifier.fillMaxWidth().height(1.dp).background(P.line))
}

/** Grupo de botones donde sólo uno queda elegido. */
@Composable
fun Segmented(options: List<Pair<String, Any>>, selected: Any, onPick: (Any) -> Unit) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        options.forEach { (label, value) ->
            val isSel = value == selected
            Box(
                Modifier.weight(1f).heightIn(min = 48.dp)
                    .clip(RoundedCornerShape(11.dp))
                    .background(if (isSel) P.panel2 else Color(0xFF0C1424))
                    .border(1.dp, if (isSel) Color(0xFF3F5A86) else P.line, RoundedCornerShape(11.dp))
                    .clickable { onPick(value) },
                contentAlignment = Alignment.Center
            ) {
                Text(
                    label,
                    color = if (isSel) P.txt else P.dim,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = with(LocalDensity.current) { 14.dp.toSp() }
                )
            }
        }
    }
}

/** Botón de elección única dentro de una rejilla (por ejemplo, quién saca primero). */
@Composable
fun PickButton(label: String, selected: Boolean, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Box(
        modifier.heightIn(min = 52.dp)
            .clip(RoundedCornerShape(11.dp))
            .background(if (selected) P.panel2 else Color(0xFF0C1424))
            .border(1.dp, if (selected) Color(0xFF3F5A86) else P.line, RoundedCornerShape(11.dp))
            .clickable { onClick() }
            .padding(horizontal = 10.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            label,
            color = if (selected) P.txt else P.dim,
            fontWeight = FontWeight.SemiBold,
            fontSize = with(LocalDensity.current) { 14.dp.toSp() },
            maxLines = 1
        )
    }
}

/** Campo de texto con etiqueta. Lo escrito se aplica al momento. */
@Composable
fun Field(label: String, value: String, onChange: (String) -> Unit, modifier: Modifier = Modifier) {
    Column(modifier) {
        Text(label, color = P.dim, fontSize = with(LocalDensity.current) { 13.dp.toSp() })
        Spacer(Modifier.height(5.dp))
        BasicTextField(
            value = value,
            onValueChange = onChange,
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
            textStyle = TextStyle(
                color = P.txt,
                fontSize = with(LocalDensity.current) { 16.dp.toSp() }
            ),
            cursorBrush = SolidColor(P.teamA),
            decorationBox = { inner ->
                Box(
                    Modifier.fillMaxWidth().heightIn(min = 50.dp)
                        .clip(RoundedCornerShape(11.dp)).background(Color(0xFF0C1424))
                        .border(1.dp, P.line, RoundedCornerShape(11.dp))
                        .padding(horizontal = 12.dp, vertical = 14.dp),
                    contentAlignment = Alignment.CenterStart
                ) { inner() }
            }
        )
    }
}

/** Botón ancho de la parte baja de las pantallas. */
@Composable
fun BigButton(
    text: String,
    primary: Boolean = false,
    danger: Boolean = false,
    onClick: () -> Unit
) {
    val bg = when {
        primary -> P.teamA
        danger -> Color(0xFF3F1D1D)
        else -> P.panel
    }
    val fg = when {
        primary -> Color(0xFF06281B)
        danger -> Color(0xFFFCA5A5)
        else -> P.txt
    }
    Box(
        Modifier.fillMaxWidth().heightIn(min = 60.dp).padding(top = 8.dp)
            .clip(RoundedCornerShape(15.dp)).background(bg)
            .border(1.dp, if (primary) bg else P.line, RoundedCornerShape(15.dp))
            .clickable { onClick() },
        contentAlignment = Alignment.Center
    ) {
        Text(
            text, color = fg, fontWeight = FontWeight.Bold,
            fontSize = with(LocalDensity.current) { 17.dp.toSp() }
        )
    }
}

/** Botón mediano de una fila. */
@Composable
fun SmallButton(text: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Box(
        modifier.heightIn(min = 50.dp).clip(RoundedCornerShape(13.dp)).background(P.panel)
            .border(1.dp, P.line, RoundedCornerShape(13.dp))
            .clickable { onClick() }
            .padding(horizontal = 16.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text, color = P.txt, fontWeight = FontWeight.SemiBold,
            fontSize = with(LocalDensity.current) { 14.dp.toSp() }
        )
    }
}

@Composable
fun Help(text: String) {
    Text(
        text, color = P.dim,
        fontSize = with(LocalDensity.current) { 12.5.dp.toSp() },
        lineHeight = with(LocalDensity.current) { 18.dp.toSp() }
    )
}
