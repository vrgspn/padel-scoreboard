package com.ismael.padel

import android.app.Application
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

enum class Screen { MATCH, SETUP, SETTINGS }

/** Aviso grande en el centro de la pantalla (cambio de lado, tie-break, set…). */
data class Banner(val big: String, val sub: String = "", val id: Long = System.currentTimeMillis())

/** Cerebro de la app: estado del partido, deshacer, voz, vibración y mando. */
class AppState(app: Application) : AndroidViewModel(app) {

    private val store = Store(app)
    private val speech = Speech(app)

    var cfg by mutableStateOf(store.loadCfg())
        private set
    var match by mutableStateOf(store.loadMatch())
        private set
    var screen by mutableStateOf(Screen.MATCH)
    var banner by mutableStateOf<Banner?>(null)
        private set
    var toast by mutableStateOf<String?>(null)
        private set

    /** Pareja que acaba de ganar el punto, para el destello de color. */
    var flashTeam by mutableStateOf(-1)
        private set
    var flashId by mutableStateOf(0L)
        private set

    /** Pulsaciones acumuladas del mando de un botón, y lo que queda de espera. */
    var burstCount by mutableStateOf(0)
        private set
    var burstId by mutableStateOf(0L)
        private set
    var lastSignal by mutableStateOf("")
        private set

    private val past = ArrayDeque<Match>()
    private val future = ArrayDeque<Match>()
    private var burstJob: Job? = null
    private var bannerJob: Job? = null
    private var toastJob: Job? = null
    private var lastPointAt = 0L

    val canUndo: Boolean get() = past.isNotEmpty()
    val canRedo: Boolean get() = future.isNotEmpty()

    // ---------------------------------------------------------------- ajustes

    fun updateCfg(block: (Cfg) -> Cfg) {
        cfg = block(cfg)
        store.saveCfg(cfg)
    }

    fun setScreen(s: Screen) {
        screen = s
    }

    // ----------------------------------------------------------------- puntos

    fun addPoint(team: Int, fromRemote: Boolean = false) {
        if (match.finished) return
        val now = System.currentTimeMillis()
        if (fromRemote && now - lastPointAt < 280) return
        lastPointAt = now

        past.addLast(match)
        if (past.size > 200) past.removeFirst()
        future.clear()

        var m = match
        if (m.startedAt == 0L) m = m.copy(startedAt = now)

        val (after, ev) = Rules.applyPoint(m, team, cfg)
        m = after
        if (ev.side && cfg.autoSwap) m = m.copy(swapped = !m.swapped)
        if (ev.match) m = m.copy(elapsed = now - (m.startedAt.takeIf { it > 0 } ?: now))
        match = m
        store.saveMatch(m)

        flashTeam = team
        flashId = now
        buzz(if (ev.match) 120 else if (ev.set) 80 else if (ev.game) 45 else 25)

        if (cfg.voice) {
            val (parts, asSentences) = Phrases.announce(m, team, ev, cfg)
            speech.say(parts, cfg.voiceRate, asSentences)
        }

        when {
            ev.match -> showBanner("🏆 " + cfg.names[m.winner], "Gana el partido " + scoreLine())
            ev.set -> showBanner("Set para " + cfg.names[team], "Van " + m.setsWon.joinToString(" - ") + " en sets")
            ev.tbStart -> showBanner(
                if (m.tbTarget == 10) "Super tie-break" else "¡Tie-break!",
                "A " + m.tbTarget + " puntos, diferencia de 2"
            )
            ev.game -> showToast("Juego para " + cfg.names[team] + " · " + m.games[0] + "-" + m.games[1])
        }
        if (ev.side && !ev.match && cfg.sideAlert) {
            viewModelScope.launch {
                delay(if (ev.game || ev.set) 1400 else 0)
                showBanner("Cambio de lado", "", 2600)
            }
        }
    }

    fun undo() {
        val prev = past.removeLastOrNull() ?: return
        future.addLast(match)
        match = prev
        store.saveMatch(prev)
        buzz(15)
        showToast("Deshecho")
        if (cfg.voice) {
            val parts = if (prev.finished) listOf("corregido", Phrases.sets(prev, cfg))
            else listOf("corregido", Phrases.points(prev, cfg), Phrases.serveLine(prev, cfg))
            speech.say(parts, cfg.voiceRate)
        }
    }

    fun redo() {
        val next = future.removeLastOrNull() ?: return
        past.addLast(match)
        match = next
        store.saveMatch(next)
        buzz(15)
    }

    fun resetScore() {
        past.clear(); future.clear()
        val swapped = match.swapped
        match = Match(swapped = swapped)
        store.saveMatch(match)
        showToast("Marcador a cero")
    }

    fun startMatch() {
        past.clear(); future.clear()
        val swapped = match.swapped
        match = Match(swapped = swapped)
        store.saveMatch(match)
        screen = Screen.MATCH
        val first = cfg.players[cfg.firstServeTeam][cfg.firstServePlayer]
        showToast("Saca $first")
        if (cfg.voice) {
            speech.say(
                listOf(
                    "empieza el partido",
                    cfg.names[0] + " contra " + cfg.names[1],
                    Phrases.serveLine(match, cfg).ifEmpty { "saca $first" }
                ),
                cfg.voiceRate
            )
        }
    }

    fun swapSides() {
        match = match.copy(swapped = !match.swapped)
        store.saveMatch(match)
    }

    fun scoreLine(): String = match.sets.joinToString("  ") { s ->
        s.a.toString() + "-" + s.b + if (s.hadTiebreak) "(" + minOf(s.tbA, s.tbB) + ")" else ""
    }

    // ------------------------------------------------------------------ mando

    /** Llega una señal del mando (tecla de volumen, botón de medios, etc.). */
    fun remoteSignal(label: String) {
        lastSignal = label
        if (cfg.oneButton) {
            pressBurst()
        } else {
            // sin modo un botón, bajar volumen es la pareja de la izquierda y subirlo la de la derecha
            val left = if (match.swapped) 1 else 0
            when (label) {
                "Volumen −", "Izquierda" -> addPoint(left, true)
                "Volumen +", "Derecha" -> addPoint(1 - left, true)
                else -> pressBurst()
            }
        }
    }

    private fun pressBurst() {
        burstJob?.cancel()
        burstCount += 1
        burstId = System.currentTimeMillis()
        if (burstCount >= 3) {
            burstCount = 0
            undo()
            return
        }
        burstJob = viewModelScope.launch {
            delay(cfg.burstWindowMs)
            val n = burstCount
            burstCount = 0
            val srv = Rules.serverOf(match, cfg).first
            when (n) {
                1 -> addPoint(srv, true)
                2 -> addPoint(1 - srv, true)
            }
        }
    }

    fun burstText(n: Int): String {
        val srv = Rules.serverOf(match, cfg).first
        return when (n) {
            1 -> "Punto para " + cfg.names[srv] + " · otra pulsación lo cambia"
            2 -> "Punto para " + cfg.names[1 - srv] + " · una más deshace"
            else -> "Deshacer"
        }
    }

    // ------------------------------------------------------------------ avisos

    fun showBanner(big: String, sub: String = "", ms: Long = 2200) {
        banner = Banner(big, sub)
        bannerJob?.cancel()
        bannerJob = viewModelScope.launch {
            delay(ms)
            banner = null
        }
    }

    fun showToast(text: String) {
        toast = text
        toastJob?.cancel()
        toastJob = viewModelScope.launch {
            delay(1900)
            toast = null
        }
    }

    // -------------------------------------------------------------- voz y tacto

    fun speakTest() {
        speech.say(
            listOf("treinta quince", Phrases.serveLine(match, cfg).ifEmpty { "saca " + Rules.serverName(match, cfg) }),
            cfg.voiceRate
        )
    }

    fun toggleVoice() {
        updateCfg { it.copy(voice = !it.voice) }
        if (cfg.voice) {
            speech.say(listOf("voz activada"), cfg.voiceRate)
            showToast("Voz activada")
        } else {
            speech.stop()
            showToast("Voz desactivada")
        }
    }

    private fun buzz(ms: Long) {
        if (!cfg.vibrate) return
        val ctx = getApplication<Application>()
        val vib = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val mgr = ctx.getSystemService(VibratorManager::class.java)
            mgr?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            ctx.getSystemService(Vibrator::class.java)
        }
        vib?.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
    }

    override fun onCleared() {
        speech.shutdown()
        super.onCleared()
    }
}
