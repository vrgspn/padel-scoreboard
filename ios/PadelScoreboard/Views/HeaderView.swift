import SwiftUI

struct HeaderView: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        let match = state.match
        HStack(spacing: 6) {
            // izquierda: sets y formato
            HStack(spacing: 6) {
                Chip(text: "Sets \(match.setsWon[0]) - \(match.setsWon[1])")
                if match.tiebreak {
                    Chip(text: match.tbTarget == 10 ? "Super tie-break" : "Tie-break")
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // centro: acciones del partido
            HStack(spacing: 6) {
                IconButton(label: "↶", enabled: state.canUndo) { state.undo() }
                IconButton(label: "↷", enabled: state.canRedo) { state.redo() }
                IconButton(label: "✚", highlighted: true) { state.setScreen(.setup) }
            }

            // derecha: voz y ajustes
            HStack(spacing: 6) {
                Spacer(minLength: 0)
                IconButton(label: state.cfg.voice ? "🔊" : "🔇", active: state.cfg.voice) {
                    state.toggleVoice()
                }
                IconButton(label: "⚙") { state.setScreen(.settings) }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

struct Chip: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(P.txt)
            .font(.system(size: 13))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(P.panel)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(P.line, lineWidth: 1))
    }
}

struct IconButton: View {
    let label: String
    var enabled: Bool = true
    var active: Bool = false
    var highlighted: Bool = false
    let action: () -> Void

    private var background: Color {
        if active { return Color(hex: 0x12251F) }
        if highlighted { return P.panel2 }
        return P.panel
    }

    private var border: Color {
        if active { return P.teamA.opacity(0.5) }
        if highlighted { return P.pickBorder }
        return P.line
    }

    private var foreground: Color {
        if active { return P.teamA }
        if highlighted { return P.txt }
        return P.dim
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .foregroundStyle(foreground)
                .font(.system(size: 19))
                .frame(width: 46, height: 46)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.32)
    }
}
