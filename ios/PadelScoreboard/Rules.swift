import Foundation

/// Reglas del partido. Sin nada de interfaz: se pueden probar por separado.
enum Rules {

    static let pointLabels = ["0", "15", "30", "40", "AD"]

    static func setsNeeded(_ cfg: Cfg) -> Int { (cfg.bestOf + 1) / 2 }

    /// Orden de saque: A1 → B1 → A2 → B2, empezando por el jugador elegido.
    static func serveOrder(_ cfg: Cfg) -> [(team: Int, player: Int)] {
        let t = cfg.firstServeTeam
        let p = cfg.firstServePlayer
        let o = 1 - t
        return [(t, p), (o, p), (t, 1 - p), (o, 1 - p)]
    }

    static func serverOf(_ m: Match, _ cfg: Cfg) -> (team: Int, player: Int) {
        let ord = serveOrder(cfg)
        if m.tiebreak {
            let n = m.tb[0] + m.tb[1]
            let i = ((m.tbStartIdx + (n + 1) / 2) % 4 + 4) % 4
            return ord[i]
        }
        let i = (m.serveIdx % 4 + 4) % 4
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

    /// Texto del tanteo que se ve en el marcador.
    static func pointLabel(_ m: Match, _ t: Int) -> String {
        m.tiebreak ? String(m.tb[t]) : pointLabels[m.pts[t]]
    }
}
