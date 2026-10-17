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
        RemoteKeys.shared.onSignal = { [weak self] label in
            Task { @MainActor in self?.remoteSignal(label) }
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

    func setScreen(_ s: Screen) {
        screen = s
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
        if ev.side && cfg.autoSwap { m.swapped.toggle() }
        if ev.match { m.elapsed = t - (m.startedAt > 0 ? m.startedAt : t) }
        match = m
        store.saveMatch(m)

        flashTeam = team
        flashId = t
        buzz(ev.match ? 120 : (ev.set ? 80 : (ev.game ? 45 : 25)))

        if cfg.voice {
            let (parts, asSentences) = Phrases.announce(m, team, ev, cfg)
            speech.say(parts, rate: cfg.voiceRate, asSentences: asSentences)
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

    func resetScore() {
        past.removeAll()
        future.removeAll()
        match = Match(swapped: match.swapped)
        store.saveMatch(match)
        showToast("Marcador a cero")
    }

    func startMatch() {
        past.removeAll()
        future.removeAll()
        match = Match(swapped: match.swapped)
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

    func swapSides() {
        match.swapped.toggle()
        store.saveMatch(match)
    }

    func scoreLine() -> String {
        match.sets.map { s in
            "\(s.a)-\(s.b)" + (s.hadTiebreak ? "(\(min(s.tbA, s.tbB)))" : "")
        }.joined(separator: "  ")
    }

    // ------------------------------------------------------------------ mando

    /// Llega una señal del mando (volumen, pulsador emparejado como teclado…).
    func remoteSignal(_ label: String) {
        lastSignal = label
        if cfg.oneButton {
            pressBurst()
            return
        }
        // sin modo un botón, bajar volumen es la pareja de la izquierda
        // y subirlo la de la derecha
        let left = match.swapped ? 1 : 0
        switch label {
        case "Volumen −", "Izquierda":
            addPoint(left, fromRemote: true)
        case "Volumen +", "Derecha":
            addPoint(1 - left, fromRemote: true)
        default:
            pressBurst()
        }
    }

    private func pressBurst() {
        burstTask?.cancel()
        burstCount += 1
        burstId = now
        if burstCount >= 3 {
            burstCount = 0
            undo()
            return
        }
        let window = UInt64(max(cfg.burstWindowMs, 200) * 1_000_000)
        burstTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: window)
            if Task.isCancelled { return }
            guard let self else { return }
            let n = self.burstCount
            self.burstCount = 0
            let srv = Rules.serverOf(self.match, self.cfg).team
            if n == 1 { self.addPoint(srv, fromRemote: true) }
            if n == 2 { self.addPoint(1 - srv, fromRemote: true) }
        }
    }

    func burstText(_ n: Int) -> String {
        let srv = Rules.serverOf(match, cfg).team
        switch n {
        case 1: return "Punto para " + cfg.names[srv] + " · otra pulsación lo cambia"
        case 2: return "Punto para " + cfg.names[1 - srv] + " · una más deshace"
        default: return "Deshacer"
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
