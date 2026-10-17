import Foundation

/**
 Estado y reglas del partido. Es una traducción directa de la versión web
 y de la app Android: mismas reglas de puntuación, misma rotación de saque
 y mismos avisos.
 */

/// Resultado de un set ya cerrado. `tbA`/`tbB` guardan el tie-break si lo hubo.
struct SetScore: Codable, Equatable {
    var a: Int
    var b: Int
    var tbA: Int = -1
    var tbB: Int = -1

    var hadTiebreak: Bool { tbA >= 0 }
    func games(_ team: Int) -> Int { team == 0 ? a : b }
    func tb(_ team: Int) -> Int { team == 0 ? tbA : tbB }

    init(a: Int, b: Int, tbA: Int = -1, tbB: Int = -1) {
        self.a = a
        self.b = b
        self.tbA = tbA
        self.tbB = tbB
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        a = (try? c.decode(Int.self, forKey: .a)) ?? 0
        b = (try? c.decode(Int.self, forKey: .b)) ?? 0
        tbA = (try? c.decode(Int.self, forKey: .tbA)) ?? -1
        tbB = (try? c.decode(Int.self, forKey: .tbB)) ?? -1
    }
}

struct Match: Codable, Equatable {
    /// 0,1,2,3 = 0/15/30/40 · 4 = ventaja
    var pts: [Int] = [0, 0]
    var games: [Int] = [0, 0]
    var setsWon: [Int] = [0, 0]
    var sets: [SetScore] = []
    var serveIdx: Int = 0
    var tiebreak: Bool = false
    var tb: [Int] = [0, 0]
    var tbTarget: Int = 7
    var tbStartIdx: Int = 0
    var swapped: Bool = false
    /// Milisegundos desde 1970, como en la versión Android.
    var startedAt: Double = 0
    var elapsed: Double = 0
    var finished: Bool = false
    var winner: Int = -1

    init() {}

    init(swapped: Bool) {
        self.swapped = swapped
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func pair(_ key: CodingKeys, _ def: [Int]) -> [Int] {
            guard let v = try? c.decode([Int].self, forKey: key), v.count == 2 else { return def }
            return v
        }
        pts = pair(.pts, [0, 0])
        games = pair(.games, [0, 0])
        setsWon = pair(.setsWon, [0, 0])
        tb = pair(.tb, [0, 0])
        sets = (try? c.decode([SetScore].self, forKey: .sets)) ?? []
        serveIdx = (try? c.decode(Int.self, forKey: .serveIdx)) ?? 0
        tiebreak = (try? c.decode(Bool.self, forKey: .tiebreak)) ?? false
        tbTarget = (try? c.decode(Int.self, forKey: .tbTarget)) ?? 7
        tbStartIdx = (try? c.decode(Int.self, forKey: .tbStartIdx)) ?? 0
        swapped = (try? c.decode(Bool.self, forKey: .swapped)) ?? false
        startedAt = (try? c.decode(Double.self, forKey: .startedAt)) ?? 0
        elapsed = (try? c.decode(Double.self, forKey: .elapsed)) ?? 0
        finished = (try? c.decode(Bool.self, forKey: .finished)) ?? false
        winner = (try? c.decode(Int.self, forKey: .winner)) ?? -1
    }
}

/// Lo que ha provocado el punto recién apuntado.
struct Events: Equatable {
    var game = false
    var set = false
    var match = false
    var side = false
    var tbStart = false
}

struct Cfg: Codable, Equatable {
    var names: [String] = ["Nosotros", "Ellos"]
    var players: [[String]] = [
        ["Jugador 1", "Jugador 2"],
        ["Jugador 3", "Jugador 4"]
    ]
    var firstServeTeam: Int = 0
    var firstServePlayer: Int = 0
    var bestOf: Int = 3
    var golden: Bool = true
    var tiebreak: Bool = true
    var superTb: Bool = false

    // mando
    var oneButton: Bool = false
    var burstWindowMs: Double = 5000
    var volumeKeys: Bool = true

    // voz
    var voice: Bool = false
    var voiceServer: Bool = true
    var voiceCourtSide: Bool = true
    var voiceSwitch: Bool = true
    var voiceRate: Double = 1.05

    // pantalla
    var vibrate: Bool = true
    var keepAwake: Bool = true
    var autoSwap: Bool = false
    var sideAlert: Bool = true

    init() {}

    /// Decodificación tolerante: si falta una clave se queda el valor por defecto,
    /// así una versión nueva de la app no pierde los ajustes guardados.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func b(_ k: CodingKeys, _ d: Bool) -> Bool { (try? c.decode(Bool.self, forKey: k)) ?? d }
        func i(_ k: CodingKeys, _ d: Int) -> Int { (try? c.decode(Int.self, forKey: k)) ?? d }
        func f(_ k: CodingKeys, _ d: Double) -> Double { (try? c.decode(Double.self, forKey: k)) ?? d }

        if let n = try? c.decode([String].self, forKey: .names), n.count == 2 { names = n }
        if let p = try? c.decode([[String]].self, forKey: .players),
           p.count == 2, p[0].count == 2, p[1].count == 2 { players = p }

        firstServeTeam = i(.firstServeTeam, 0)
        firstServePlayer = i(.firstServePlayer, 0)
        bestOf = i(.bestOf, 3)
        golden = b(.golden, true)
        tiebreak = b(.tiebreak, true)
        superTb = b(.superTb, false)
        oneButton = b(.oneButton, false)
        burstWindowMs = f(.burstWindowMs, 5000)
        volumeKeys = b(.volumeKeys, true)
        voice = b(.voice, false)
        voiceServer = b(.voiceServer, true)
        voiceCourtSide = b(.voiceCourtSide, true)
        voiceSwitch = b(.voiceSwitch, true)
        voiceRate = f(.voiceRate, 1.05)
        vibrate = b(.vibrate, true)
        keepAwake = b(.keepAwake, true)
        autoSwap = b(.autoSwap, false)
        sideAlert = b(.sideAlert, true)
    }
}
