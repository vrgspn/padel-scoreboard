package com.ismael.padel

import android.os.Bundle
import android.view.KeyEvent
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.ismael.padel.ui.BannerOverlay
import com.ismael.padel.ui.BurstOverlay
import com.ismael.padel.ui.MatchScreen
import com.ismael.padel.ui.P
import com.ismael.padel.ui.SettingsScreen
import com.ismael.padel.ui.SetupScreen
import com.ismael.padel.ui.ToastOverlay
import com.ismael.padel.ui.WinnerOverlay

/**
 * Única pantalla de la app. Aquí se capturan las teclas del mando:
 * a diferencia de una web, una app Android SÍ recibe las teclas de volumen,
 * que es lo que envían la mayoría de pulsadores de foto.
 */
class MainActivity : ComponentActivity() {

    private val state: AppState by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { PadelApp(state) }
    }

    override fun onResume() {
        super.onResume()
        applyKeepAwake()
    }

    private fun applyKeepAwake() {
        if (state.cfg.keepAwake) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (event != null && event.repeatCount > 0) return true
        val label = labelFor(keyCode) ?: return super.onKeyDown(keyCode, event)
        if (!state.cfg.volumeKeys && (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN)) {
            return super.onKeyDown(keyCode, event)
        }
        state.remoteSignal(label)
        return true   // consumida: el volumen del móvil no cambia
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        val isRemote = labelFor(keyCode) != null
        val volume = keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN
        if (volume && !state.cfg.volumeKeys) return super.onKeyUp(keyCode, event)
        return if (isRemote) true else super.onKeyUp(keyCode, event)
    }

    /** Teclas que puede mandar un pulsador de foto o un mando Bluetooth. */
    private fun labelFor(keyCode: Int): String? = when (keyCode) {
        KeyEvent.KEYCODE_VOLUME_DOWN -> "Volumen −"
        KeyEvent.KEYCODE_VOLUME_UP -> "Volumen +"
        KeyEvent.KEYCODE_CAMERA, KeyEvent.KEYCODE_FOCUS -> "Disparador"
        KeyEvent.KEYCODE_HEADSETHOOK, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
        KeyEvent.KEYCODE_MEDIA_PLAY, KeyEvent.KEYCODE_MEDIA_PAUSE -> "Play/Pausa"
        KeyEvent.KEYCODE_MEDIA_NEXT -> "Pista siguiente"
        KeyEvent.KEYCODE_MEDIA_PREVIOUS -> "Pista anterior"
        KeyEvent.KEYCODE_ENTER, KeyEvent.KEYCODE_NUMPAD_ENTER, KeyEvent.KEYCODE_DPAD_CENTER -> "Enter"
        KeyEvent.KEYCODE_SPACE -> "Espacio"
        KeyEvent.KEYCODE_DPAD_LEFT -> "Izquierda"
        KeyEvent.KEYCODE_DPAD_RIGHT -> "Derecha"
        else -> null
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) applyKeepAwake()
    }
}

@Composable
fun PadelApp(state: AppState) {
    Box(Modifier.fillMaxSize().background(P.bg)) {
        when (state.screen) {
            Screen.MATCH -> MatchScreen(state)
            Screen.SETUP -> SetupScreen(state)
            Screen.SETTINGS -> SettingsScreen(state)
        }

        if (state.screen == Screen.MATCH) WinnerOverlay(state)

        // avisos por encima de todo
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { BannerOverlay(state) }
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { BurstOverlay(state) }
        Box(
            Modifier.fillMaxSize().padding(bottom = 18.dp),
            contentAlignment = Alignment.BottomCenter
        ) { ToastOverlay(state) }
    }
}
