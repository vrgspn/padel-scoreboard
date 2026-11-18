import Foundation

/// Reglas del partido. Sin nada de interfaz: se pueden probar por separado.
enum Rules {

    static let pointLabels = ["0", "15", "30", "40", "AD"]

    static func setsNeeded(_ cfg: Cfg) -> Int { (cfg.bestOf + 1) / 2 }

    /// Orden de saque: empieza el jugador elegido; luego el del mismo lado de la otra pareja,
    /// el compañero del primero y, por último, el compañero de ese.
    static func serveOrder(_ t: Int, _ p: Int) -> [(team: Int, player: Int)] {
        let o = 1 - t
        return [(t, p), (o, p), (t, 1 - p), (o, 1 - p)]
    }

    /// Turno de saque sin el ajuste manual.
    static func rawServeIdx(_ m: Match) -> Int {
        m.tiebreak ? m.tbStartIdx + (m.tb[0] + m.tb[1] + 1) / 2 : m.serveIdx
    }

    static func serverOf(_ m: Match, _ cfg: Cfg) -> (team: Int, player: Int) {
        let ord = m.serveBaseTeam >= 0
            ? serveOrder(m.serveBaseTeam, m.serveBasePlayer)
            : serveOrder(cfg.firstServeTeam, cfg.firstServePlayer)
        let i = ((rawServeIdx(m) - m.serveOff) % 4 + 4) % 4
        return ord[i]
    }

    static func serverName(_ m: Match, _ cfg: Cfg) -> String {
        let s = serverOf(m, cfg)
        return cfg.players[s.team][s.player]
    }

    /// Lado del saque: suma de puntos par = derecha, impar = izquierda.
    static func serveSide(_ m: Match) -> String {
        let n = m.tiebreak ? m.tb[0] + m.tb[1] : m.pts[0] + m.pts[1]
        return n % 2 == 0 ? "derecha" : "izquierda"
    }

    /// Aplica un punto a la pareja `t`. Devuelve el nuevo estado y lo que ha pasado.
    static func applyPoint(_ match: Match, _ t: Int, _ cfg: Cfg) -> (Match, Events) {
        if match.finished { return (match, Events()) }
        var m = match
        var ev = Events()
        let o = 1 - t

        if m.tiebreak {
            m.tb[t] += 1
            let target = m.tbTarget > 0 ? m.tbTarget : 7
            if m.tb[t] >= target && m.tb[t] - m.tb[o] >= 2 {
                m.games[t] += 1
                m.serveIdx += 1
                return endSet(m, t, ev, fromTb: true, cfg)
            } else if (m.tb[0] + m.tb[1]) % 6 == 0 {
                ev.side = true
            }
            return (m, ev)
        }

        if m.pts[t] < 3 {
            m.pts[t] += 1
            return (m, ev)
        }
        if m.pts[t] == 3 {
            if m.pts[o] < 3 {
                return endGame(m, t, ev, cfg)
            }
            if m.pts[o] == 3 {
                if cfg.golden { return endGame(m, t, ev, cfg) }
                m.pts[t] = 4
                return (m, ev)
            }
            // el rival tenía ventaja y la pierde
            m.pts[o] = 3
            return (m, ev)
        }
        // tenía ventaja: gana el juego
        return endGame(m, t, ev, cfg)
    }

    private static func endGame(_ match: Match, _ t: Int, _ events: Events, _ cfg: Cfg) -> (Match, Events) {
        var ev = events
        ev.game = true
        let o = 1 - t
        var m = match
        m.games[t] += 1
        m.pts = [0, 0]
        m.serveIdx += 1

        if m.games[t] >= 6 && m.games[t] - m.games[o] >= 2 {
            return endSet(m, t, ev, fromTb: false, cfg)
        }
        if cfg.tiebreak && m.games[0] == 6 && m.games[1] == 6 {
            m.tiebreak = true
            m.tb = [0, 0]
            m.tbTarget = 7
            m.tbStartIdx = m.serveIdx
            ev.tbStart = true
        }
        if (m.games[0] + m.games[1]) % 2 == 1 { ev.side = true }
        return (m, ev)
    }

    private static func endSet(_ match: Match, _ t: Int, _ events: Events, fromTb: Bool, _ cfg: Cfg) -> (Match, Events) {
        var ev = events
        ev.set = true
        let score = fromTb
            ? SetScore(a: match.games[0], b: match.games[1], tbA: match.tb[0], tbB: match.tb[1])
            : SetScore(a: match.games[0], b: match.games[1])

        var m = match
        m.setsWon[t] += 1
        m.sets.append(score)

        if m.setsWon[t] >= setsNeeded(cfg) {
            m.finished = true
            m.winner = t
            ev.match = true
            return (m, ev)
        }

        m.games = [0, 0]
        m.pts = [0, 0]
        m.tiebreak = false
        m.tb = [0, 0]
        m.tbTarget = 7
        ev.side = true

        let n = setsNeeded(cfg) - 1
        if cfg.superTb && m.setsWon[0] == n && m.setsWon[1] == n {
            m.tiebreak = true
            m.tbTarget = 10
            m.tbStartIdx = m.serveIdx
            ev.tbStart = true
        }
        return (m, ev)
    }

    /// Qué se juega la pareja `t` en el punto siguiente: "", juego, break, set o partido.
    static func stake(_ m: Match, _ t: Int, _ cfg: Cfg) -> String {
        if m.finished { return "" }
        let ev = applyPoint(m, t, cfg).1
        if ev.match { return "Punto de partido" }
        if ev.set { return "Punto de set" }
        if ev.game { return serverOf(m, cfg).team == t ? "Punto de juego" : "Break" }
        return ""
    }

    // MARK: - Ajustar marcador

    /// ¿El marcador a mano se juega a tie-break? 0 = no, 7 = tie-break, 10 = super tie-break.
    static func adjTbTarget(_ e: Adjust, _ cfg: Cfg) -> Int {
        let n = setsNeeded(cfg) - 1
        if cfg.superTb && n > 0 && e.sets[0] == n && e.sets[1] == n { return 10 }
        if cfg.tiebreak && e.games[0] == 6 && e.games[1] == 6 { return 7 }
        return 0
    }

    /// Motivo por el que el marcador a mano no vale, o "" si se puede guardar.
    static func adjProblem(_ e: Adjust, _ cfg: Cfg) -> String {
        let tgt = adjTbTarget(e, cfg)
        for t in 0..<2 {
            let o = 1 - t
            if tgt != 10 && e.games[t] >= 6 && e.games[t] - e.games[o] >= 2 {
                return "Con \(e.games[0])-\(e.games[1]) el set ya estaría ganado: súmalo en sets."
            }
            if tgt > 0 && e.pts[t] >= tgt && e.pts[t] - e.pts[o] >= 2 {
                return "Con \(e.pts[0])-\(e.pts[1]) el tie-break ya estaría ganado."
            }
        }
        return ""
    }

    /// Valores iniciales del diálogo a partir del partido en curso.
    static func adjustFrom(_ m: Match, _ cfg: Cfg) -> Adjust {
        var sets = m.setsWon
        // un partido acabado se abre con el último set aún por cerrar
        if m.finished && m.winner >= 0 { sets[m.winner] = min(sets[m.winner], setsNeeded(cfg) - 1) }
        return Adjust(pts: m.tiebreak ? m.tb : m.pts, games: m.games, sets: sets)
    }

    /// Un paso (+1/−1) en una casilla del diálogo: fila 0 = juego, 1 = juegos, 2 = sets.
    static func adjStep(_ e: Adjust, row: Int, team t: Int, by d: Int, _ cfg: Cfg) -> Adjust {
        let o = 1 - t
        let before = adjTbTarget(e, cfg)
        var r = e
        switch row {
        case 0:
            if before > 0 {
                r.pts[t] = max(0, r.pts[t] + d)
            } else {
                // ventaja sólo sin punto de oro y con el rival en 40
                let top = (!cfg.golden && r.pts[o] >= 3) ? 4 : 3
                r.pts[t] = min(top, max(0, r.pts[t] + d))
                if r.pts[t] == 4 && r.pts[o] == 4 { r.pts[o] = 3 }
                if r.pts[o] == 4 && r.pts[t] < 3 { r.pts[o] = 3 }
            }
        case 1:
            r.games[t] = min(cfg.tiebreak ? 6 : 30, max(0, r.games[t] + d))
        default:
            r.sets[t] = min(setsNeeded(cfg) - 1, max(0, r.sets[t] + d))
            if adjTbTarget(r, cfg) == 10 { r.games = [0, 0] }
        }
        // si cambia entre juego normal y tie-break, el tanteo del juego empieza de cero
        if (adjTbTarget(r, cfg) > 0) != (before > 0) { r.pts = [0, 0] }
        return r
    }

    /// Pone el partido en el marcador a mano. El orden de saque sigue a los juegos jugados.
    static func applyAdjust(_ match: Match, _ e: Adjust, _ cfg: Cfg) -> Match {
        let tgt = adjTbTarget(e, cfg)
        var m = match
        let sameSets = m.setsWon == e.sets
        if sameSets { m.serveIdx += (e.games[0] + e.games[1]) - (m.games[0] + m.games[1]) }
        // historial de sets: quita o añade (sin resultado conocido) los que cambien
        for t in 0..<2 {
            var d = e.sets[t] - m.setsWon[t]
            while d < 0, let i = m.sets.lastIndex(where: { $0.winner == t }) {
                m.sets.remove(at: i)
                d += 1
            }
            while d > 0 {
                m.sets.append(SetScore(a: -1, b: -1, w: t))
                d -= 1
            }
        }
        let wasTb = m.tiebreak && sameSets && m.games == e.games
        m.setsWon = e.sets
        m.games = e.games
        m.tiebreak = tgt > 0
        m.tbTarget = tgt > 0 ? tgt : 7
        m.tb = tgt > 0 ? e.pts : [0, 0]
        m.pts = tgt > 0 ? [0, 0] : e.pts
        if tgt > 0 && !wasTb { m.tbStartIdx = m.serveIdx }
        m.finished = false
        m.winner = -1
        m.elapsed = 0
        return m
    }

    /// Texto del tanteo que se ve en el marcador.
    static func pointLabel(_ m: Match, _ t: Int) -> String {
        m.tiebreak ? String(m.tb[t]) : pointLabels[m.pts[t]]
    }
}
