package com.ismael.padel

import android.content.Context
import android.speech.tts.TextToSpeech
import java.util.Locale

/**
 * Voz del marcador. Las frases son las mismas que en la versión web:
 * cada bloque se dice del tirón, entre bloques una coma, y el fin de juego,
 * set o partido se separa en frases con punto.
 */
class Speech(context: Context) {

    private var tts: TextToSpeech? = null
    private var ready = false

    init {
        tts = TextToSpeech(context.applicationContext) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.language = Locale("es", "ES")
                ready = true
            }
        }
    }

    fun setRate(rate: Float) {
        tts?.setSpeechRate(rate)
    }

    fun stop() {
        tts?.stop()
    }

    fun shutdown() {
        tts?.stop()
        tts?.shutdown()
        tts = null
    }

    /** Une los trozos con coma; [asSentences] los separa con punto. */
    fun say(parts: List<String>, rate: Float, asSentences: Boolean = false) {
        if (!ready) return
        val clean = parts.map { it.replace(Regex("[.,;:]+"), " ").replace(Regex("\\s+"), " ").trim() }
            .filter { it.isNotEmpty() }
        if (clean.isEmpty()) return

        val text = if (asSentences)
            clean.joinToString(". ") { it.replaceFirstChar { c -> c.uppercase() } } + "."
        else
            (clean.joinToString(", ")).replaceFirstChar { it.uppercase() } + "."

        tts?.setSpeechRate(rate)
        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "padel")
    }

    fun say(text: String, rate: Float) = say(listOf(text), rate)
}

/** Construcción de las frases, separada de la voz para poder probarla. */
object Phrases {

    private val POINTS = listOf("cero", "quince", "treinta", "cuarenta")
    private val NUMBERS = listOf(
        "cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete",
        "ocho", "nueve", "diez", "once", "doce", "trece", "catorce", "quince"
    )

    fun nw(n: Int): String = if (n in NUMBERS.indices) NUMBERS[n] else n.toString()

    /** Tanteo del juego en curso, empezando por quien saca. */
    fun points(m: Match, cfg: Cfg): String {
        val srv = Rules.serverOf(m, cfg).first
        val rec = 1 - srv
        if (m.tiebreak) {
            return if (m.tb[srv] == m.tb[rec]) "iguales a " + nw(m.tb[srv])
            else nw(m.tb[srv]) + " " + nw(m.tb[rec])
        }
        val a = m.pts[srv]
        val b = m.pts[rec]
        return when {
            a == 4 -> "ventaja " + cfg.names[srv]
            b == 4 -> "ventaja " + cfg.names[rec]
            a == 3 && b == 3 -> if (cfg.golden) "cuarenta iguales punto de oro" else "iguales"
            a == b -> POINTS[a] + " iguales"
            else -> POINTS[a] + " " + POINTS[b]
        }
    }

    fun serveLine(m: Match, cfg: Cfg): String {
        if (m.finished) return ""
        val side = if (cfg.voiceCourtSide) " desde la " + Rules.serveSide(m) else ""
        return when {
            cfg.voiceServer -> "saca " + Rules.serverName(m, cfg) + side
            cfg.voiceCourtSide -> "saque desde la " + Rules.serveSide(m)
            else -> ""
        }
    }

    fun games(m: Match, cfg: Cfg, alreadySaid: Int = -1): String {
        val g = m.games
        if (g[0] == 0 && g[1] == 0) return ""
        if (g[0] == g[1]) return "iguales a " + nw(g[0])
        val l = if (g[0] > g[1]) 0 else 1
        val tail = if (alreadySaid == l) "" else " para " + cfg.names[l]
        return nw(g[l]) + " " + nw(g[1 - l]) + tail
    }

    fun sets(m: Match, cfg: Cfg): String {
        val a = m.setsWon[0]
        val b = m.setsWon[1]
        if (a == b) return "empate a " + if (a == 1) "un set" else nw(a) + " sets"
        val l = if (a > b) 0 else 1
        val n = m.setsWon[l]
        val part = if (n == 1) "un set a " else nw(n) + " sets a "
        return cfg.names[l] + " gana " + part + nw(m.setsWon[1 - l])
    }

    /** El super tie-break se canta por sus puntos, no por el juego. */
    fun setScore(s: SetScore, t: Int): String {
        val sup = s.hadTiebreak && (s.a + s.b) == 1
        val a = if (sup) s.tb(t) else s.games(t)
        val b = if (sup) s.tb(1 - t) else s.games(1 - t)
        return nw(a) + " " + nw(b)
    }

    /**
     * Devuelve las partes a decir y si van separadas por punto (fin de juego/set/partido)
     * o por coma (tanteo dentro del juego).
     */
    fun announce(m: Match, t: Int, ev: Events, cfg: Cfg): Pair<List<String>, Boolean> {
        val parts = mutableListOf<String>()
        val change = if (ev.side && !ev.match && cfg.voiceSwitch) "cambio de lado" else ""

        if (ev.match) {
            parts += "juego set y partido para " + cfg.names[m.winner]
            parts += m.sets.joinToString(" ") { setScore(it, m.winner) }
            return parts to true
        }
        if (ev.set) {
            val s = m.sets.last()
            parts += "juego y set para " + cfg.names[t]
            parts += setScore(s, t)
            parts += sets(m, cfg)
            if (ev.tbStart) parts += "se decide en super tie break a " + nw(m.tbTarget) + " puntos"
            parts += change
            parts += serveLine(m, cfg)
            return parts to true
        }
        if (ev.game) {
            parts += "juego para " + cfg.names[t]
            parts += games(m, cfg, t)
            if (ev.tbStart) parts += "tie break"
            parts += change
            parts += serveLine(m, cfg)
            return parts to true
        }

        parts += points(m, cfg)
        parts += change
        parts += serveLine(m, cfg)
        for (k in 0..1) {
            val s = Rules.stake(m, k, cfg)
            if (s == "Punto de set" || s == "Punto de partido") {
                parts += s.lowercase() + " para " + cfg.names[k]
            }
        }
        return parts to false
    }
}
