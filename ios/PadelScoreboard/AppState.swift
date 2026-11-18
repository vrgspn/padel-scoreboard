import Combine
import Foundation
import SwiftUI

enum Screen {
    case match, setup, settings
}

/// Aviso grande en el centro de la pantalla (cambio de lado, tie-break, set…).
struct Banner: Equatable {
    var big: String
    var sub: String = ""
    var id: Double = Date().timeIntervalSince1970 * 1000
}

/// Cerebro de la app: estado del partido, deshacer, voz, vibración y mando.
@MainActor
final class AppState: ObservableObject {

    private let store = Store()
    private let speech = Speech()

    @Published private(set) var cfg: Cfg
    @Published private(set) var match: Match
    @Published var screen: Screen = .match
    @Published private(set) var banner: Banner?
    @Published private(set) var toast: String?

    /// Pareja que acaba de ganar el punto, para el destello de color.
    @Published private(set) var flashTeam = -1
    @Published private(set) var flashId: Double = 0

    /// Pulsaciones acumuladas del mando de un botón, y lo que queda de espera.
    @Published private(set) var burstCount = 0
    @Published private(set) var burstId: Double = 0
    @Published private(set) var lastSignal = ""

    @Published private var past: [Match] = []
    @Published private var future: [Match] = []

    private var burstTask: Task<Void, Never>?
    private var bannerTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?
    private var sideTask: Task<Void, Never>?
    private var lastPointAt: Double = 0

    var canUndo: Bool { !past.isEmpty }
    var canRedo: Bool { !future.isEmpty }

    private var now: Double { Date().timeIntervalSince1970 * 1000 }

    init() {
        cfg = store.loadCfg()
        match = store.loadMatch()
        Haptics.prepare()
        RemoteKeys.shared.volumeKeysEnabled = cfg.volumeKeys
        RemoteKeys.shared.onSignal = { [weak self] label, phase in
            Task { @MainActor in
                switch phase {
                case .down: self?.remoteDown(label)
                case .up: self?.remoteUp(label)
                case .tap: self?.remoteTap(label)
                }
            }
        }
        RemoteKeys.shared.start()
        applyKeepAwake()
    }

    // ---------------------------------------------------------------- ajustes

    func updateCfg(_ block: (Cfg) -> Cfg) {
        cfg = block(cfg)
        store.saveCfg(cfg)
        RemoteKeys.shared.volumeKeysEnabled = cfg.volumeKeys
        applyKeepAwake()
    }

    /// Evita que la pantalla se apague durante el partido.
    func applyKeepAwake() {
        UIApplication.shared.isIdleTimerDisabled = cfg.keepAwake
    }

    // ----------------------------------------------------------------- puntos

    func addPoint(_ team: Int, fromRemote: Bool = false) {
        if match.finished { return }
        let t = now
        if fromRemote && t - lastPointAt < 280 { return }
        lastPointAt = t

        past.append(match)
        if past.count > 200 { past.removeFirst() }
        future.removeAll()

        var m = match
        if m.startedAt == 0 { m.startedAt = t }

        let (after, ev) = Rules.applyPoint(m, team, cfg)
        m = after
        if ev.match { m.elapsed = t - (m.startedAt > 0 ? m.startedAt : t) }
        match = m
        store.saveMatch(m)

        flashTeam = team
        flashId = t
        buzz(ev.match ? 120 : (ev.set ? 80 : (ev.game ? 45 : 25)))

        if cfg.voice {
            let (parts, asSentences) = Phrases.announce(m, team, ev, cfg)
            speech.say(
                parts, rate: cfg.voiceRate, asSentences: asSentences,
                extra: Guasa.phrase(winner: team, ev, cfg)
            )
        }

        if ev.match {
            showBanner("🏆 " + cfg.names[m.winner], sub: "Gana el partido " + scoreLine())
        } else if ev.set {
            showBanner(
                "Set para " + cfg.names[team],
                sub: "Van \(m.setsWon[0]) - \(m.setsWon[1]) en sets"
            )
        } else if ev.tbStart {
            showBanner(
                m.tbTarget == 10 ? "Super tie-break" : "¡Tie-break!",
                sub: "A \(m.tbTarget) puntos, diferencia de 2"
            )
        } else if ev.game {
            showToast("Juego para " + cfg.names[team] + " · \(m.games[0])-\(m.games[1])")
        }

        if ev.side && !ev.match && cfg.sideAlert {
            sideTask?.cancel()
            let wait: UInt64 = (ev.game || ev.set) ? 1_400_000_000 : 0
            sideTask = Task { [weak self] in
                if wait > 0 { try? await Task.sleep(nanoseconds: wait) }
                if Task.isCancelled { return }
                self?.showBanner("Cambio de lado", sub: "", ms: 2600)
            }
        }
    }

    func undo() {
        guard let prev = past.popLast() else { return }
        future.append(match)
        match = prev
        store.saveMatch(prev)
        buzz(15)
        showToast("Deshecho")
        if cfg.voice {
            let parts = prev.finished
                ? ["corregido", Phrases.sets(prev, cfg)]
                : ["corregido", Phrases.points(prev, cfg), Phrases.serveLine(prev, cfg)]
            speech.say(parts, rate: cfg.voiceRate)
        }
    }

    func redo() {
        guard let next = future.popLast() else { return }
        past.append(match)
        match = next
        store.saveMatch(next)
        buzz(15)
    }

    /// Desde ya saca `team`/`player`: el tanteo sigue igual y el orden continúa desde él.
    func setServer(team: Int, player: Int) {
        guard !match.finished else { return }
        let fresh = match.startedAt == 0 && past.isEmpty
        if !fresh {
            past.append(match)
            if past.count > 200 { past.removeFirst() }
            future.removeAll()
        }
        var m = match
        m.serveBaseTeam = team
        m.serveBasePlayer = player
        m.serveOff = Rules.rawServeIdx(match)
        match = m
        store.saveMatch(m)
        // antes del primer punto también es el saque inicial
        if fresh { updateCfg { var c = $0; c.firstServeTeam = team; c.firstServePlayer = player; return c } }
        buzz(20)
        let name = cfg.players[team][player]
        showToast("Saca " + name)
        if cfg.voice {
            let line = Phrases.serveLine(m, cfg)
            speech.say([line.isEmpty ? "saca " + name : line], rate: cfg.voiceRate)
        }
    }

    /// Saque inicial desde la configuración; si aún no se ha jugado, manda sobre lo elegido arriba.
    func setFirstServe(team: Int, player: Int) {
        updateCfg { var c = $0; c.firstServeTeam = team; c.firstServePlayer = player; return c }
        if match.startedAt == 0 && past.isEmpty && match.serveBaseTeam >= 0 {
            match.serveBaseTeam = -1
            match.serveBasePlayer = 0
            match.serveOff = 0
            store.saveMatch(match)
        }
    }

    /// Pone el marcador a mano (por si se olvidó apuntar algún punto). Se puede deshacer.
    func adjustScore(_ e: Adjust) {
        guard Rules.adjProblem(e, cfg).isEmpty else { return }
        past.append(match)
        if past.count > 200 { past.removeFirst() }
        future.removeAll()
        let m = Rules.applyAdjust(match, e, cfg)
        match = m
        store.saveMatch(m)
        buzz(20)
        showToast("Marcador ajustado")
        if cfg.voice {
            speech.say(["marcador ajustado", Phrases.points(m, cfg), Phrases.serveLine(m, cfg)], rate: cfg.voiceRate)
        }
    }

    func resetScore() {
        past.removeAll()
        future.removeAll()
        match = Match()
        store.saveMatch(match)
        showToast("Marcador a cero")
    }

    func startMatch() {
        past.removeAll()
        future.removeAll()
        match = Match()
        store.saveMatch(match)
        screen = .match
        let first = cfg.players[cfg.firstServeTeam][cfg.firstServePlayer]
        showToast("Saca " + first)
        if cfg.voice {
            let line = Phrases.serveLine(match, cfg)
            speech.say(
                [
                    "empieza el partido",
                    cfg.names[0] + " contra " + cfg.names[1],
                    line.isEmpty ? "saca " + first : line
                ],
                rate: cfg.voiceRate
            )
        }
    }

    func scoreLine() -> String {
        match.sets.map { s in
            !s.known ? "?-?" : "\(s.a)-\(s.b)" + (s.hadTiebreak ? "(\(min(s.tbA, s.tbB)))" : "")
        }.joined(separator: "  ")
    }

    // ------------------------------------------------------------------ mando

    /*
     Mando de un botón, pensado para que no salten puntos en el bolsillo:
       1 pulsación          → no cuenta
       2 pulsaciones        → punto para la pareja de la izquierda (A)
       3 pulsaciones        → punto para la pareja de la derecha (B)
       4 o más              → no cuenta
       mantener 3 segundos  → deshacer
     Las pulsaciones se cuentan al soltar y se resuelven cuando pasa la espera
     entre pulsaciones sin que llegue otra.
     */

    static let holdUndoMs: Double = 3000
    /// Hueco máximo entre saltos de volumen para considerarlos el mismo botón mantenido.
    private static let streamGapMs: Double = 700

    private var holdTask: Task<Void, Never>?
    private var holdFired = false
    private var keyHeld = false
    private var streamStart: Double = 0
    private var streamLast: Double = 0
    private var streamUndone = false

    /// Sin modo un botón, bajar volumen es la pareja A (izquierda) y subirlo la B (derecha).
    private func directTeam(_ label: String) -> Int? {
        guard !cfg.oneButton else { return nil }
        switch label {
        case "Volumen −", "Izquierda": return 0
        case "Volumen +", "Derecha": return 1
        default: return nil
        }
    }

    /// Se aprieta un botón del mando (pulsador emparejado como teclado).
    func remoteDown(_ label: String) {
        lastSignal = label
        if let team = directTeam(label) {
            addPoint(team, fromRemote: true)
            return
        }
        keyHeld = true
        holdFired = false
        burstTask?.cancel()              // mientras está apretado no se resuelve nada
        holdTask?.cancel()
        holdTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(AppState.holdUndoMs * 1_000_000))
            if Task.isCancelled { return }
            guard let self else { return }
            self.holdFired = true
            self.holdUndo()
        }
    }

    /// Se suelta el botón del mando.
    func remoteUp(_ label: String) {
        if directTeam(label) != nil || !keyHeld { return }
        keyHeld = false
        holdTask?.cancel()
        if holdFired {                   // fue un «mantener»: ya se deshizo
            holdFired = false
            if burstCount > 0 { restartBurstWait() }
            return
        }
        burstCount += 1
        restartBurstWait()
    }

    /// Pulsación sin suelta conocida (saltos de volumen). Mantener el botón
    /// llega como una ráfaga continua de saltos: si dura 3 s, se deshace.
    func remoteTap(_ label: String) {
        lastSignal = label
        if let team = directTeam(label) {
            addPoint(team, fromRemote: true)
            return
        }
        let t = now
        if t - streamLast > AppState.streamGapMs {
            streamStart = t
            streamUndone = false
        }
        streamLast = t
        if streamUndone { return }
        if t - streamStart >= AppState.holdUndoMs {
            streamUndone = true
            holdUndo()
            return
        }
        burstCount += 1
        restartBurstWait()
    }

    private func holdUndo() {
        burstTask?.cancel()
        burstCount = 0
        if canUndo { undo() } else { showToast("Nada que deshacer") }
    }

    private func restartBurstWait() {
        burstId = now
        burstTask?.cancel()
        let window = UInt64(max(cfg.burstWindowMs, 200) * 1_000_000)
        burstTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: window)
            if Task.isCancelled { return }
            guard let self else { return }
            let n = self.burstCount
            self.burstCount = 0
            switch n {
            case 2: self.addPoint(0, fromRemote: true)
            case 3: self.addPoint(1, fromRemote: true)
            case 1: break                // una sola pulsación: probablemente el bolsillo
            default: self.showToast("Demasiadas pulsaciones: no se apunta nada")
            }
        }
    }

    func burstText(_ n: Int) -> String {
        switch n {
        case 1: return "Una pulsación no cuenta · 2 = " + cfg.names[0] + " · 3 = " + cfg.names[1]
        case 2: return "Punto para " + cfg.names[0] + " · una más: " + cfg.names[1]
        case 3: return "Punto para " + cfg.names[1]
        default: return "Demasiadas pulsaciones: no se apuntará"
        }
    }

    // ------------------------------------------------------------------ avisos

    func showBanner(_ big: String, sub: String = "", ms: Double = 2200) {
        banner = Banner(big: big, sub: sub, id: now)
        bannerTask?.cancel()
        bannerTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(ms * 1_000_000))
            if Task.isCancelled { return }
            self?.banner = nil
        }
    }

    func showToast(_ text: String) {
        toast = text
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_900_000_000)
            if Task.isCancelled { return }
            self?.toast = nil
        }
    }

    // -------------------------------------------------------------- voz y tacto

    func speakTest() {
        let line = Phrases.serveLine(match, cfg)
        speech.say(
            ["treinta quince", line.isEmpty ? "saca " + Rules.serverName(match, cfg) : line],
            rate: cfg.voiceRate
        )
    }

    func toggleVoice() {
        updateCfg { var c = $0; c.voice.toggle(); return c }
        if cfg.voice {
            speech.say(["voz activada"], rate: cfg.voiceRate)
            showToast("Voz activada")
        } else {
            speech.stop()
            showToast("Voz desactivada")
        }
    }

    private func buzz(_ ms: Int) {
        guard cfg.vibrate else { return }
        Haptics.buzz(ms)
    }
}
