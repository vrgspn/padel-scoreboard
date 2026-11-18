package com.vrgspn.marcadorpadel

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

/** Tiempo que hay que mantener apretado el mando para deshacer. */
const val HOLD_UNDO_MS = 3000L

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
        if (ev.match) m = m.copy(elapsed = now - (m.startedAt.takeIf { it > 0 } ?: now))
        match = m
        store.saveMatch(m)

        flashTeam = team
        flashId = now
        buzz(if (ev.match) 120 else if (ev.set) 80 else if (ev.game) 45 else 25)

        if (cfg.voice) {
            val (parts, asSentences) = Phrases.announce(m, team, ev, cfg)
            speech.say(parts, cfg.voiceRate, asSentences, Guasa.phrase(team, ev, cfg))
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

    /** Desde ya saca [team]/[player]: el tanteo sigue igual y el orden continúa desde él. */
    fun setServer(team: Int, player: Int) {
        if (match.finished) return
        val fresh = match.startedAt == 0L && past.isEmpty()
        if (!fresh) {
            past.addLast(match)
            if (past.size > 200) past.removeFirst()
            future.clear()
        }
        val m = match.copy(serveBaseTeam = team, serveBasePlayer = player, serveOff = Rules.rawServeIdx(match))
        match = m
        store.saveMatch(m)
        // antes del primer punto también es el saque inicial
        if (fresh) updateCfg { it.copy(firstServeTeam = team, firstServePlayer = player) }
        buzz(20)
        val name = cfg.players[team][player]
        showToast("Saca $name")
        if (cfg.voice) speech.say(listOf(Phrases.serveLine(m, cfg).ifEmpty { "saca $name" }), cfg.voiceRate)
    }

    /** Saque inicial desde la configuración; si aún no se ha jugado, manda sobre lo elegido arriba. */
    fun setFirstServe(team: Int, player: Int) {
        updateCfg { it.copy(firstServeTeam = team, firstServePlayer = player) }
        if (match.startedAt == 0L && past.isEmpty() && match.serveBaseTeam >= 0) {
            match = match.copy(serveBaseTeam = -1, serveBasePlayer = 0, serveOff = 0)
            store.saveMatch(match)
        }
    }

    /** Pone el marcador a mano (por si se olvidó apuntar algún punto). Se puede deshacer. */
    fun adjustScore(e: Adjust) {
        if (Rules.adjProblem(e, cfg).isNotEmpty()) return
        past.addLast(match)
        if (past.size > 200) past.removeFirst()
        future.clear()
        val m = Rules.applyAdjust(match, e, cfg)
        match = m
        store.saveMatch(m)
        buzz(20)
        showToast("Marcador ajustado")
        if (cfg.voice) {
            speech.say(listOf("marcador ajustado", Phrases.points(m, cfg), Phrases.serveLine(m, cfg)), cfg.voiceRate)
        }
    }

    fun resetScore() {
        past.clear(); future.clear()
        match = Match()
        store.saveMatch(match)
        showToast("Marcador a cero")
    }

    fun startMatch() {
        past.clear(); future.clear()
        match = Match()
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

    fun scoreLine(): String = match.sets.joinToString("  ") { s ->
        if (!s.known) "?-?" else s.a.toString() + "-" + s.b + if (s.hadTiebreak) "(" + minOf(s.tbA, s.tbB) + ")" else ""
    }

    // ------------------------------------------------------------------ mando

    /*
     * Mando de un botón, pensado para que no salten puntos en el bolsillo:
     *   1 pulsación          → no cuenta
     *   2 pulsaciones        → punto para la pareja de la izquierda (A)
     *   3 pulsaciones        → punto para la pareja de la derecha (B)
     *   4 o más              → no cuenta
     *   mantener 3 segundos  → deshacer
     * Las pulsaciones se cuentan al soltar y se resuelven cuando pasa la espera
     * entre pulsaciones sin que llegue otra.
     */

    private var keyHeld = false   // hay un botón apretado del que aún no ha llegado la suelta
    private var holdFired = false
    private var holdJob: Job? = null

    private fun isDirectKey(label: String) = !cfg.oneButton &&
        label in setOf("Volumen −", "Izquierda", "Volumen +", "Derecha")

    /** Se aprieta un botón del mando (tecla de volumen, botón de medios, etc.). */
    fun remoteDown(label: String) {
        lastSignal = label
        if (isDirectKey(label)) {
            // sin modo un botón, bajar volumen es la pareja A (izquierda) y subirlo la B (derecha)
            addPoint(if (label == "Volumen −" || label == "Izquierda") 0 else 1, true)
            return
        }
        // (las repeticiones de una tecla mantenida ya se filtran antes de llegar aquí)
        keyHeld = true
        holdFired = false
        burstJob?.cancel()              // mientras está apretado no se resuelve nada
        holdJob?.cancel()
        holdJob = viewModelScope.launch {
            delay(HOLD_UNDO_MS)
            holdFired = true
            burstCount = 0
            if (canUndo) undo() else showToast("Nada que deshacer")
        }
    }

    /** Se suelta el botón del mando. */
    fun remoteUp(label: String) {
        if (isDirectKey(label) || !keyHeld) return
        keyHeld = false
        holdJob?.cancel()
        if (holdFired) {                // fue un «mantener»: ya se deshizo
            holdFired = false
            if (burstCount > 0) restartBurstWait()
            return
        }
        burstCount += 1
        restartBurstWait()
    }

    private fun restartBurstWait() {
        burstId = System.currentTimeMillis()
        burstJob?.cancel()
        burstJob = viewModelScope.launch {
            delay(cfg.burstWindowMs)
            val n = burstCount
            burstCount = 0
            when (n) {
                2 -> addPoint(0, true)
                3 -> addPoint(1, true)
                1 -> {}                  // una sola pulsación: probablemente el bolsillo
                else -> showToast("Demasiadas pulsaciones: no se apunta nada")
            }
        }
    }

    fun burstText(n: Int): String = when (n) {
        1 -> "Una pulsación no cuenta · 2 = " + cfg.names[0] + " · 3 = " + cfg.names[1]
        2 -> "Punto para " + cfg.names[0] + " · una más: " + cfg.names[1]
        3 -> "Punto para " + cfg.names[1]
        else -> "Demasiadas pulsaciones: no se apuntará"
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
