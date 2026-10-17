import AVFoundation
import Foundation

/**
 Voz del marcador, con la voz del sistema en español.
 Cada bloque se dice del tirón, entre bloques una coma, y el fin de juego,
 set o partido se separa en frases con punto, igual que en la versión web.
 */
final class Speech {

    private let synth = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice?

    init() {
        // La mejor voz española disponible: si hay una «enhanced» o «premium», esa.
        let spanish = AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("es") }
        let preferred = spanish.first { $0.language == "es-ES" && $0.quality != .default }
            ?? spanish.first { $0.language == "es-ES" }
            ?? spanish.first { $0.quality != .default }
            ?? spanish.first
        voice = preferred ?? AVSpeechSynthesisVoice(language: "es-ES")
        configureSession()
    }

    /// Hablamos por encima de la música, bajándola un momento en vez de cortarla.
    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(
            .playback,
            mode: .spokenAudio,
            options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
        )
        try? session.setActive(true, options: [])
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }

    /// Une los trozos con coma; `asSentences` los separa con punto.
    func say(_ parts: [String], rate: Double, asSentences: Bool = false) {
        let clean = parts
            .map { clean($0) }
            .filter { !$0.isEmpty }
        guard !clean.isEmpty else { return }

        let text: String
        if asSentences {
            text = clean.map { capitalizedFirst($0) }.joined(separator: ". ") + "."
        } else {
            text = capitalizedFirst(clean.joined(separator: ", ")) + "."
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        // La velocidad normal de iOS es 0.5; la de la app va de 0,9 a 1,3.
        let base = Double(AVSpeechUtteranceDefaultSpeechRate)
        let value = Float(base * rate)
        utterance.rate = min(max(value, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        utterance.postUtteranceDelay = 0

        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance)
    }

    func say(_ text: String, rate: Double) {
        say([text], rate: rate)
    }

    private func clean(_ s: String) -> String {
        let noPunct = s.replacingOccurrences(
            of: "[.,;:]+", with: " ", options: .regularExpression
        )
        return noPunct
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func capitalizedFirst(_ s: String) -> String {
        guard let first = s.first else { return s }
        return String(first).uppercased() + s.dropFirst()
    }
}
