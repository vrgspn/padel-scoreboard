import AVFoundation
import GameController
import MediaPlayer
import SwiftUI
import UIKit

/**
 Mando a distancia (pulsador de fotos Bluetooth).

 En Android basta con quedarse las teclas de volumen. En iOS el sistema no
 deja interceptarlas, así que se escucha por dos caminos a la vez:

 1. Teclado Bluetooth (GameController): Enter, espacio y flechas, que es lo que
    envían muchos pulsadores cuando se emparejan como teclado.
 2. Cambios de volumen del sistema: cuando el pulsador sube o baja el volumen,
    se detecta el salto y se apunta el punto. Para que el volumen no se quede
    atascado en el tope, la app lo vuelve a centrar sola.
 */
final class RemoteKeys {

    static let shared = RemoteKeys()

    /// Se avisa con la misma etiqueta que usa la versión Android.
    var onSignal: ((String) -> Void)?
    var volumeKeysEnabled = true

    private var volumeObservation: NSKeyValueObservation?
    private var lastVolume: Float = 0.5
    private var ignoreOwnChanges = 0
    private weak var volumeSlider: UISlider?
    private var started = false

    private init() {}

    func start() {
        guard !started else { return }
        started = true
        observeKeyboards()
        observeVolume()
    }

    // ------------------------------------------------------------- teclado

    private func observeKeyboards() {
        if let keyboard = GCKeyboard.coalesced { attach(keyboard) }
        NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidConnect, object: nil, queue: .main
        ) { [weak self] note in
            if let keyboard = note.object as? GCKeyboard { self?.attach(keyboard) }
        }
    }

    private func attach(_ keyboard: GCKeyboard) {
        keyboard.keyboardInput?.keyChangedHandler = { [weak self] _, _, keyCode, pressed in
            guard pressed, let label = RemoteKeys.label(for: keyCode) else { return }
            DispatchQueue.main.async { self?.onSignal?(label) }
        }
    }

    /// Teclas que puede mandar un pulsador emparejado como teclado.
    private static func label(for code: GCKeyCode) -> String? {
        switch code {
        case .returnOrEnter, .keypadEnter: return "Enter"
        case .spacebar: return "Espacio"
        case .leftArrow: return "Izquierda"
        case .rightArrow: return "Derecha"
        case .upArrow: return "Arriba"
        case .downArrow: return "Abajo"
        default: return nil
        }
    }

    // ------------------------------------------------------------- volumen

    private func observeVolume() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        lastVolume = session.outputVolume
        volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let value = change.newValue else { return }
            DispatchQueue.main.async { self?.handleVolume(value) }
        }
    }

    private func handleVolume(_ value: Float) {
        let previous = lastVolume
        lastVolume = value

        if ignoreOwnChanges > 0 {
            ignoreOwnChanges -= 1
            return
        }
        guard volumeKeysEnabled else { return }

        let delta = value - previous
        guard abs(delta) > 0.001 else { return }
        onSignal?(delta > 0 ? "Volumen +" : "Volumen −")

        // En los topes dejaría de haber saltos: se vuelve al centro.
        if value <= 0.02 || value >= 0.98 { setSystemVolume(0.5) }
    }

    private func setSystemVolume(_ target: Float) {
        guard let slider = volumeSlider else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            self.ignoreOwnChanges += 1
            self.lastVolume = target
            slider.value = target
            slider.sendActions(for: .valueChanged)
        }
    }

    func registerVolumeSlider(_ slider: UISlider?) {
        volumeSlider = slider
    }
}

/**
 Control de volumen del sistema metido en la pantalla pero invisible.
 Sirve para dos cosas: poder recentrar el volumen y evitar que salga
 el cartel de volumen del sistema encima del marcador.
 */
struct HiddenVolumeView: UIViewRepresentable {

    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: CGRect(x: -3000, y: -3000, width: 1, height: 1))
        view.alpha = 0.0001
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            let slider = view.subviews.compactMap { $0 as? UISlider }.first
            RemoteKeys.shared.registerVolumeSlider(slider)
        }
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
