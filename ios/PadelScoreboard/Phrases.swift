import Foundation

/// Construcción de las frases que canta el marcador, separada de la voz
/// para poder probarla. Son las mismas que en la versión web y Android.
enum Phrases {

    private static let pointWords = ["cero", "quince", "treinta", "cuarenta"]
    private static let numbers = [
        "cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete",
        "ocho", "nueve", "diez", "once", "doce", "trece", "catorce", "quince"
    ]

    static func nw(_ n: Int) -> String {
        (n >= 0 && n < numbers.count) ? numbers[n] : String(n)
    }

    /// Tanteo del juego en curso, empezando por quien saca.
    static func points(_ m: Match, _ cfg: Cfg) -> String {
        let srv = Rules.serverOf(m, cfg).team
        let rec = 1 - srv
        if m.tiebreak {
            return m.tb[srv] == m.tb[rec]
                ? "iguales a " + nw(m.tb[srv])
                : nw(m.tb[srv]) + " " + nw(m.tb[rec])
        }
        let a = m.pts[srv]
        let b = m.pts[rec]
        if a == 4 { return "ventaja " + cfg.names[srv] }
        if b == 4 { return "ventaja " + cfg.names[rec] }
        if a == 3 && b == 3 { return cfg.golden ? "cuarenta iguales punto de oro" : "iguales" }
        if a == b { return pointWords[a] + " iguales" }
        return pointWords[a] + " " + pointWords[b]
    }

    static func serveLine(_ m: Match, _ cfg: Cfg) -> String {
        if m.finished { return "" }
        let side = cfg.voiceCourtSide ? " desde la " + Rules.serveSide(m) : ""
        if cfg.voiceServer { return "saca " + Rules.serverName(m, cfg) + side }
        if cfg.voiceCourtSide { return "saque desde la " + Rules.serveSide(m) }
        return ""
    }

    static func games(_ m: Match, _ cfg: Cfg, alreadySaid: Int = -1) -> String {
        let g = m.games
        if g[0] == 0 && g[1] == 0 { return "" }
        if g[0] == g[1] { return "iguales a " + nw(g[0]) }
        let l = g[0] > g[1] ? 0 : 1
        let tail = alreadySaid == l ? "" : " para " + cfg.names[l]
        return nw(g[l]) + " " + nw(g[1 - l]) + tail
    }

    static func sets(_ m: Match, _ cfg: Cfg) -> String {
        let a = m.setsWon[0]
        let b = m.setsWon[1]
        if a == b { return "empate a " + (a == 1 ? "un set" : nw(a) + " sets") }
        let l = a > b ? 0 : 1
        let n = m.setsWon[l]
        let part = n == 1 ? "un set a " : nw(n) + " sets a "
        return cfg.names[l] + " gana " + part + nw(m.setsWon[1 - l])
    }

    /// El super tie-break se canta por sus puntos, no por el juego.
    static func setScore(_ s: SetScore, _ t: Int) -> String {
        let sup = s.hadTiebreak && (s.a + s.b) == 1
        let a = sup ? s.tb(t) : s.games(t)
        let b = sup ? s.tb(1 - t) : s.games(1 - t)
        return nw(a) + " " + nw(b)
    }

    /// Devuelve las partes a decir y si van separadas por punto (fin de juego,
    /// set o partido) o por coma (tanteo dentro del juego).
    static func announce(_ m: Match, _ t: Int, _ ev: Events, _ cfg: Cfg) -> ([String], Bool) {
        var parts: [String] = []
        let change = (ev.side && !ev.match && cfg.voiceSwitch) ? "cambio de lado" : ""

        if ev.match {
            parts.append("juego set y partido para " + cfg.names[m.winner])
            parts.append(m.sets.map { setScore($0, m.winner) }.joined(separator: " "))
            return (parts, true)
        }
        if ev.set {
            let s = m.sets.last ?? SetScore(a: 0, b: 0)
            parts.append("juego y set para " + cfg.names[t])
            parts.append(setScore(s, t))
            parts.append(sets(m, cfg))
            if ev.tbStart { parts.append("se decide en super tie break a " + nw(m.tbTarget) + " puntos") }
            parts.append(change)
            parts.append(serveLine(m, cfg))
            return (parts, true)
        }
        if ev.game {
            parts.append("juego para " + cfg.names[t])
            parts.append(games(m, cfg, alreadySaid: t))
            if ev.tbStart { parts.append("tie break") }
            parts.append(change)
            parts.append(serveLine(m, cfg))
            return (parts, true)
        }

        parts.append(points(m, cfg))
        parts.append(change)
        parts.append(serveLine(m, cfg))
        for k in 0...1 {
            let s = Rules.stake(m, k, cfg)
            if s == "Punto de set" || s == "Punto de partido" {
                parts.append(s.lowercased() + " para " + cfg.names[k])
            }
        }
        return (parts, false)
    }
}
