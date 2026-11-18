package com.vrgspn.marcadorpadel

/**
 * Estado y reglas del partido. Es una traducción directa de la versión web:
 * mismas reglas de puntuación, misma rotación de saque y mismos avisos.
 */

/**
 * Resultado de un set ya cerrado. [tbA]/[tbB] guardan el tie-break si lo hubo.
 * Los sets sumados a mano al ajustar el marcador no saben su resultado
 * (a = b = -1) y guardan quién lo ganó en [w].
 */
data class SetScore(val a: Int, val b: Int, val tbA: Int = -1, val tbB: Int = -1, val w: Int = -1) {
    val hadTiebreak: Boolean get() = tbA >= 0
    val known: Boolean get() = a >= 0
    val winner: Int get() = if (w >= 0) w else if (a > b) 0 else 1
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
    /** Quién se eligió a mano para sacar (-1 = el saque inicial de los ajustes) y en qué turno. */
    val serveBaseTeam: Int = -1,
    val serveBasePlayer: Int = 0,
    val serveOff: Int = 0,
    val startedAt: Long = 0L,
    val elapsed: Long = 0L,
    val finished: Boolean = false,
    val winner: Int = -1
)

/**
 * Marcador puesto a mano: [pts] es el tanteo del juego (0..4 = 0/15/30/40/AD)
 * o, en tie-break, sus puntos; [games] los juegos del set y [sets] los sets ganados.
 */
data class Adjust(val pts: List<Int>, val games: List<Int>, val sets: List<Int>)

/** Lo que ha provocado el punto recién apuntado. */
data class Events(
    val game: Boolean = false,
    val set: Boolean = false,
    val match: Boolean = false,
    val side: Boolean = false,
    val tbStart: Boolean = false
)

/** Nombres por defecto: en cada pareja, el de la izquierda (0) y el de la derecha (1). */
val DEFAULT_PLAYERS = listOf(
    listOf("Izquierda A", "Derecha A"),
    listOf("Izquierda B", "Derecha B")
)

/** Nombres por defecto de versiones anteriores, que se cambian al cargar. */
val OLD_DEFAULT_PLAYERS = listOf(
    listOf("Jugador 1", "Jugador 2"),
    listOf("Jugador 3", "Jugador 4")
)

data class Cfg(
    val names: List<String> = listOf("Nosotros", "Ellos"),
    /** Por pareja: [jugador de la izquierda, jugador de la derecha]. */
    val players: List<List<String>> = DEFAULT_PLAYERS,
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
    /** Modo guasa: tras el tanteo, a veces se mete con quien pierde o alaba a quien gana. */
    val guasa: Boolean = false,
    // pantalla (la pareja A siempre a la izquierda y la B a la derecha)
    val vibrate: Boolean = true,
    val keepAwake: Boolean = true,
    val fullscreen: Boolean = true,
    val sideAlert: Boolean = true
)

object Rules {

    val POINT_LABELS = listOf("0", "15", "30", "40", "AD")

    fun setsNeeded(cfg: Cfg) = (cfg.bestOf + 1) / 2

    /**
     * Orden de saque: empieza el jugador elegido; luego el del mismo lado de la otra pareja,
     * el compañero del primero y, por último, el compañero de ese.
     */
    fun serveOrder(t: Int, p: Int): List<Pair<Int, Int>> {
        val o = 1 - t
        return listOf(t to p, o to p, t to (1 - p), o to (1 - p))
    }

    /** Turno de saque sin el ajuste manual. */
    fun rawServeIdx(m: Match): Int =
        if (m.tiebreak) m.tbStartIdx + (m.tb[0] + m.tb[1] + 1) / 2 else m.serveIdx

    fun serverOf(m: Match, cfg: Cfg): Pair<Int, Int> {
        val ord = if (m.serveBaseTeam >= 0) serveOrder(m.serveBaseTeam, m.serveBasePlayer)
        else serveOrder(cfg.firstServeTeam, cfg.firstServePlayer)
        return ord[((rawServeIdx(m) - m.serveOff) % 4 + 4) % 4]
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

    // ------------------------------------------------------ ajustar marcador

    /** ¿El marcador a mano se juega a tie-break? 0 = no, 7 = tie-break, 10 = super tie-break. */
    fun adjTbTarget(e: Adjust, cfg: Cfg): Int {
        val n = setsNeeded(cfg) - 1
        if (cfg.superTb && n > 0 && e.sets[0] == n && e.sets[1] == n) return 10
        if (cfg.tiebreak && e.games[0] == 6 && e.games[1] == 6) return 7
        return 0
    }

    /** Motivo por el que el marcador a mano no vale, o "" si se puede guardar. */
    fun adjProblem(e: Adjust, cfg: Cfg): String {
        val tgt = adjTbTarget(e, cfg)
        for (t in 0..1) {
            val o = 1 - t
            if (tgt != 10 && e.games[t] >= 6 && e.games[t] - e.games[o] >= 2)
                return "Con ${e.games[0]}-${e.games[1]} el set ya estaría ganado: súmalo en sets."
            if (tgt > 0 && e.pts[t] >= tgt && e.pts[t] - e.pts[o] >= 2)
                return "Con ${e.pts[0]}-${e.pts[1]} el tie-break ya estaría ganado."
        }
        return ""
    }

    /** Valores iniciales del diálogo a partir del partido en curso. */
    fun adjustFrom(m: Match, cfg: Cfg): Adjust {
        val sets = m.setsWon.toMutableList()
        // un partido acabado se abre con el último set aún por cerrar
        if (m.finished && m.winner >= 0) sets[m.winner] = minOf(sets[m.winner], setsNeeded(cfg) - 1)
        return Adjust(if (m.tiebreak) m.tb else m.pts, m.games, sets)
    }

    /** Un paso (+1/−1) en una casilla del diálogo: fila 0 = juego, 1 = juegos, 2 = sets. */
    fun adjStep(e: Adjust, row: Int, t: Int, d: Int, cfg: Cfg): Adjust {
        val o = 1 - t
        val before = adjTbTarget(e, cfg)
        var pts = e.pts.toMutableList()
        var games = e.games.toMutableList()
        val sets = e.sets.toMutableList()
        when (row) {
            0 -> if (before > 0) {
                pts[t] = maxOf(0, pts[t] + d)
            } else {
                // ventaja sólo sin punto de oro y con el rival en 40
                val max = if (!cfg.golden && pts[o] >= 3) 4 else 3
                pts[t] = (pts[t] + d).coerceIn(0, max)
                if (pts[t] == 4 && pts[o] == 4) pts[o] = 3
                if (pts[o] == 4 && pts[t] < 3) pts[o] = 3
            }
            1 -> games[t] = (games[t] + d).coerceIn(0, if (cfg.tiebreak) 6 else 30)
            else -> {
                sets[t] = (sets[t] + d).coerceIn(0, setsNeeded(cfg) - 1)
                if (adjTbTarget(Adjust(pts, games, sets), cfg) == 10) games = mutableListOf(0, 0)
            }
        }
        // si cambia entre juego normal y tie-break, el tanteo del juego empieza de cero
        if ((adjTbTarget(Adjust(pts, games, sets), cfg) > 0) != (before > 0)) pts = mutableListOf(0, 0)
        return Adjust(pts, games, sets)
    }

    /** Pone el partido en el marcador a mano. El orden de saque sigue a los juegos jugados. */
    fun applyAdjust(m: Match, e: Adjust, cfg: Cfg): Match {
        val tgt = adjTbTarget(e, cfg)
        val sameSets = m.setsWon == e.sets
        val serveIdx = if (sameSets) m.serveIdx + (e.games.sum() - m.games.sum()) else m.serveIdx
        // historial de sets: quita o añade (sin resultado conocido) los que cambien
        val hist = m.sets.toMutableList()
        for (t in 0..1) {
            var d = e.sets[t] - m.setsWon[t]
            while (d < 0) {
                val i = hist.indexOfLast { it.winner == t }
                if (i < 0) break
                hist.removeAt(i); d++
            }
            repeat(maxOf(0, d)) { hist += SetScore(-1, -1, w = t) }
        }
        val wasTb = m.tiebreak && sameSets && m.games == e.games
        return m.copy(
            pts = if (tgt > 0) listOf(0, 0) else e.pts,
            games = e.games,
            setsWon = e.sets,
            sets = hist,
            serveIdx = serveIdx,
            tiebreak = tgt > 0,
            tb = if (tgt > 0) e.pts else listOf(0, 0),
            tbTarget = if (tgt > 0) tgt else 7,
            tbStartIdx = if (tgt > 0 && !wasTb) serveIdx else m.tbStartIdx,
            finished = false,
            winner = -1,
            elapsed = 0L
        )
    }

    /** Texto del tanteo que se ve en el marcador. */
    fun pointLabel(m: Match, t: Int): String =
        if (m.tiebreak) m.tb[t].toString() else POINT_LABELS[m.pts[t]]
}

/** Devuelve una copia de la lista con el valor cambiado en esa posición. */
fun List<Int>.replace(index: Int, value: Int): List<Int> =
    toMutableList().also { it[index] = value }
