import SwiftUI

struct HeaderView: View {

    @EnvironmentObject private var state: AppState
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var pickServer = false

    /// En un iPhone, botones algo más pequeños para que quepa todo.
    private var btn: CGFloat { hSize == .compact ? 40 : 46 }
    private var gap: CGFloat { hSize == .compact ? 4 : 6 }

    var body: some View {
        let match = state.match
        HStack(spacing: gap) {
            // izquierda: tie-break (los sets ya se ven como pelotas bajo cada tanteo)
            HStack(spacing: 6) {
                if match.tiebreak {
                    Chip(text: match.tbTarget == 10 ? "Super tie-break" : "Tie-break")
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // centro: acciones del partido
            HStack(spacing: gap) {
                IconButton(label: "↶", enabled: state.canUndo, size: btn) { state.undo() }
                IconButton(label: "↷", enabled: state.canRedo, size: btn) { state.redo() }
                IconButton(label: "🎾", enabled: !match.finished, size: btn) { pickServer = true }
                IconButton(label: "✚", highlighted: true, size: btn) { state.screen = .setup }
            }

            // derecha: voz y ajustes
            HStack(spacing: gap) {
                Spacer(minLength: 0)
                IconButton(label: state.cfg.voice ? "🔊" : "🔇", active: state.cfg.voice, size: btn) {
                    state.toggleVoice()
                }
                IconButton(label: "⚙", size: btn) { state.screen = .settings }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, hSize == .compact ? 8 : 10)
        .padding(.vertical, 8)
        .confirmationDialog("¿Quién saca ahora?", isPresented: $pickServer, titleVisibility: .visible) {
            ForEach(Self.order, id: \.self) { k in
                serverButton(team: k / 2, player: k % 2)
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("El tanteo no cambia. Después saca el del mismo lado de la otra pareja, luego el compañero del elegido y por último el compañero de ese.")
        }
    }

    /// Derecha A, izquierda A, derecha B, izquierda B (equipo * 2 + jugador).
    private static let order = [1, 0, 3, 2]

    private func serverButton(team t: Int, player p: Int) -> some View {
        let cur = Rules.serverOf(state.match, state.cfg)
        let sel = cur.team == t && cur.player == p
        let name = state.cfg.players[t][p]
        let side = name == Cfg.defaultPlayers[t][p] ? "" : (p == 1 ? " · derecha" : " · izquierda")
        return Button((sel ? "🎾 " : "") + name + side + " (" + state.cfg.names[t] + ")") {
            if !sel { state.setServer(team: t, player: p) }
        }
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
    var size: CGFloat = 46
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
                .font(.system(size: size < 46 ? 17 : 19))
                .frame(width: size, height: size)
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
