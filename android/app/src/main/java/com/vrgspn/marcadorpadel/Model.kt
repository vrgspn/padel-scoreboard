package com.vrgspn.marcadorpadel

/**
 * Estado y reglas del partido. Es una traducción directa de la versión web:
 * mismas reglas de puntuación, misma rotación de saque y mismos avisos.
 */

/** Resultado de un set ya cerrado. [tb] guarda el tie-break si lo hubo. */
data class SetScore(val a: Int, val b: Int, val tbA: Int = -1, val tbB: Int = -1) {
    val hadTiebreak: Boolean get() = tbA >= 0
    fun games(team: Int) = if (team == 0) a else b
    fun tb(team: Int) = if (team == 0) tbA else tbB
}

data class Match(
    val pts: List<Int> = listOf(0, 0),          // 0,1,2,3 = 0/15/30/40 · 4 = ventaja
    val games: List<Int> = listOf(0, 0),
    val setsWon: List<Int> = listOf(0, 0),
    val sets: List<SetScore> = emptyList(),
    val serveIdx: Int = 0,
    val tiebreak: Boolean = false,
    val tb: List<Int> = listOf(0, 0),
    val tbTarget: Int = 7,
    val tbStartIdx: Int = 0,
    val swapped: Boolean = false,
    val startedAt: Long = 0L,
    val elapsed: Long = 0L,
    val finished: Boolean = false,
    val winner: Int = -1
)

/** Lo que ha provocado el punto recién apuntado. */
data class Events(
    val game: Boolean = false,
    val set: Boolean = false,
    val match: Boolean = false,
    val side: Boolean = false,
    val tbStart: Boolean = false
)

data class Cfg(
    val names: List<String> = listOf("Nosotros", "Ellos"),
    val players: List<List<String>> = listOf(
        listOf("Jugador 1", "Jugador 2"),
        listOf("Jugador 3", "Jugador 4")
    ),
    val firstServeTeam: Int = 0,
    val firstServePlayer: Int = 0,
    val bestOf: Int = 3,
    val golden: Boolean = true,
    val tiebreak: Boolean = true,
    val superTb: Boolean = false,
    // mando
    val oneButton: Boolean = false,
    val burstWindowMs: Long = 5000L,
    val volumeKeys: Boolean = true,
    // voz
    val voice: Boolean = false,
    val voiceServer: Boolean = true,
    val voiceCourtSide: Boolean = true,
    val voiceSwitch: Boolean = true,
    val voiceRate: Float = 1.05f,
    // pantalla
    val vibrate: Boolean = true,
    val keepAwake: Boolean = true,
    val autoSwap: Boolean = false,
    val sideAlert: Boolean = true
)

object Rules {

    val POINT_LABELS = listOf("0", "15", "30", "40", "AD")

    fun setsNeeded(cfg: Cfg) = (cfg.bestOf + 1) / 2

    /** Orden de saque: A1 → B1 → A2 → B2, empezando por el jugador elegido. */
    fun serveOrder(cfg: Cfg): List<Pair<Int, Int>> {
        val t = cfg.firstServeTeam
        val p = cfg.firstServePlayer
        val o = 1 - t
        return listOf(t to p, o to p, t to (1 - p), o to (1 - p))
    }

    fun serverOf(m: Match, cfg: Cfg): Pair<Int, Int> {
        val ord = serveOrder(cfg)
        if (m.tiebreak) {
            val n = m.tb[0] + m.tb[1]
            return ord[((m.tbStartIdx + (n + 1) / 2) % 4 + 4) % 4]
        }
        return ord[(m.serveIdx % 4 + 4) % 4]
    }

    fun serverName(m: Match, cfg: Cfg): String {
        val (t, p) = serverOf(m, cfg)
        return cfg.players[t][p]
    }

    /** Lado del saque: suma de puntos par = derecha, impar = izquierda. */
    fun serveSide(m: Match): String {
        val n = if (m.tiebreak) m.tb[0] + m.tb[1] else m.pts[0] + m.pts[1]
        return if (n % 2 == 0) "derecha" else "izquierda"
    }

    /** Aplica un punto a la pareja [t]. Devuelve el nuevo estado y lo que ha pasado. */
    fun applyPoint(match: Match, t: Int, cfg: Cfg): Pair<Match, Events> {
        if (match.finished) return match to Events()
        var m = match
        var ev = Events()
        val o = 1 - t

        if (m.tiebreak) {
            m = m.copy(tb = m.tb.replace(t, m.tb[t] + 1))
            val target = if (m.tbTarget > 0) m.tbTarget else 7
            if (m.tb[t] >= target && m.tb[t] - m.tb[o] >= 2) {
                m = m.copy(games = m.games.replace(t, m.games[t] + 1), serveIdx = m.serveIdx + 1)
                val r = endSet(m, t, ev, true, cfg); m = r.first; ev = r.second
            } else if ((m.tb[0] + m.tb[1]) % 6 == 0) {
                ev = ev.copy(side = true)
            }
            return m to ev
        }

        if (m.pts[t] < 3) {
            return m.copy(pts = m.pts.replace(t, m.pts[t] + 1)) to ev
        }
        if (m.pts[t] == 3) {
            if (m.pts[o] < 3) {
                val r = endGame(m, t, ev, cfg); return r.first to r.second
            }
            if (m.pts[o] == 3) {
                return if (cfg.golden) {
                    val r = endGame(m, t, ev, cfg); r.first to r.second
                } else {
                    m.copy(pts = m.pts.replace(t, 4)) to ev
                }
            }
            // el rival tenía ventaja y la pierde
            return m.copy(pts = m.pts.replace(o, 3)) to ev
        }
        // tenía ventaja: gana el juego
        val r = endGame(m, t, ev, cfg)
        return r.first to r.second
    }

    private fun endGame(match: Match, t: Int, events: Events, cfg: Cfg): Pair<Match, Events> {
        var ev = events.copy(game = true)
        val o = 1 - t
        var m = match.copy(
            games = match.games.replace(t, match.games[t] + 1),
            pts = listOf(0, 0),
            serveIdx = match.serveIdx + 1
        )
        if (m.games[t] >= 6 && m.games[t] - m.games[o] >= 2) {
            return endSet(m, t, ev, false, cfg)
        }
        if (cfg.tiebreak && m.games[0] == 6 && m.games[1] == 6) {
            m = m.copy(tiebreak = true, tb = listOf(0, 0), tbTarget = 7, tbStartIdx = m.serveIdx)
            ev = ev.copy(tbStart = true)
        }
        if ((m.games[0] + m.games[1]) % 2 == 1) ev = ev.copy(side = true)
        return m to ev
    }

    private fun endSet(match: Match, t: Int, events: Events, fromTb: Boolean, cfg: Cfg): Pair<Match, Events> {
        var ev = events.copy(set = true)
        val score = if (fromTb)
            SetScore(match.games[0], match.games[1], match.tb[0], match.tb[1])
        else
            SetScore(match.games[0], match.games[1])

        var m = match.copy(
            setsWon = match.setsWon.replace(t, match.setsWon[t] + 1),
            sets = match.sets + score
        )

        if (m.setsWon[t] >= setsNeeded(cfg)) {
            return m.copy(finished = true, winner = t) to ev.copy(match = true)
        }

        m = m.copy(games = listOf(0, 0), pts = listOf(0, 0), tiebreak = false, tb = listOf(0, 0), tbTarget = 7)
        ev = ev.copy(side = true)

        val n = setsNeeded(cfg) - 1
        if (cfg.superTb && m.setsWon[0] == n && m.setsWon[1] == n) {
            m = m.copy(tiebreak = true, tbTarget = 10, tbStartIdx = m.serveIdx)
            ev = ev.copy(tbStart = true)
        }
        return m to ev
    }

    /** Qué se juega la pareja [t] en el punto siguiente: "", juego, break, set o partido. */
    fun stake(m: Match, t: Int, cfg: Cfg): String {
        if (m.finished) return ""
        val ev = applyPoint(m, t, cfg).second
        return when {
            ev.match -> "Punto de partido"
            ev.set -> "Punto de set"
            ev.game -> if (serverOf(m, cfg).first == t) "Punto de juego" else "Break"
            else -> ""
        }
    }

    /** Texto del tanteo que se ve en el marcador. */
    fun pointLabel(m: Match, t: Int): String =
        if (m.tiebreak) m.tb[t].toString() else POINT_LABELS[m.pts[t]]
}

/** Devuelve una copia de la lista con el valor cambiado en esa posición. */
fun List<Int>.replace(index: Int, value: Int): List<Int> =
    toMutableList().also { it[index] = value }
