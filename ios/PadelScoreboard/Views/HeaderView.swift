import SwiftUI

struct HeaderView: View {

    @EnvironmentObject private var state: AppState
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var pickServer = false
    @State private var adjusting = false

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
                IconButton(label: "✎", size: btn) { adjusting = true }
                IconButton(label: "✚", highlighted: true, size: btn) { state.screen = .setup }
            }

            // derecha: voz y ajustes (en un iPhone, sin repartir hueco: así caben las acciones)
            HStack(spacing: gap) {
                Spacer(minLength: 0)
                IconButton(label: state.cfg.voice ? "🔊" : "🔇", active: state.cfg.voice, size: btn) {
                    state.toggleVoice()
                }
                IconButton(label: "⚙", size: btn) { state.screen = .settings }
            }
            .frame(maxWidth: hSize == .compact ? nil : .infinity, alignment: .trailing)
            .fixedSize(horizontal: hSize == .compact, vertical: false)
        }
        .sheet(isPresented: $adjusting) {
            AdjustSheet().environmentObject(state)
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

/// Ajustar marcador: dos columnas (A y B) con el juego, los juegos del set y los sets.
struct AdjustSheet: View {

    @EnvironmentObject private var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var e: Adjust?

    var body: some View {
        let cfg = state.cfg
        let cur = e ?? Rules.adjustFrom(state.match, cfg)
        let tgt = Rules.adjTbTarget(cur, cfg)
        let problem = Rules.adjProblem(cur, cfg)
        let labels = [tgt == 10 ? "Super tie-break" : (tgt > 0 ? "Tie-break" : "Juego actual"),
                      "Juegos del set", "Sets ganados"]
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("✎  Ajustar marcador")
                    .foregroundStyle(P.txt)
                    .font(.system(size: 22, weight: .heavy))
                Help("Por si se olvidó apuntar algún punto. Al guardar, el partido sigue desde aquí y se puede deshacer con ↶.")
                HStack(spacing: 10) {
                    ForEach(0..<2, id: \.self) { t in
                        Text(cfg.names[t].uppercased())
                            .foregroundStyle(P.team(t))
                            .font(.system(size: 15, weight: .heavy))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 6)
                ForEach(0..<3, id: \.self) { row in
                    Text(labels[row])
                        .foregroundStyle(P.dim)
                        .font(.system(size: 13))
                        .padding(.top, 4)
                    HStack(spacing: 10) {
                        ForEach(0..<2, id: \.self) { t in
                            let v = row == 0 ? cur.pts[t] : (row == 1 ? cur.games[t] : cur.sets[t])
                            let locked = row == 1 && tgt == 10   // el super tie-break se juega sin juegos
                            Stepper2(
                                text: row == 0 && tgt == 0 ? Rules.pointLabels[v] : String(v),
                                color: P.team(t),
                                canDown: !locked && v > 0,
                                canUp: !locked,
                                onDown: { e = Rules.adjStep(cur, row: row, team: t, by: -1, cfg) },
                                onUp: { e = Rules.adjStep(cur, row: row, team: t, by: 1, cfg) }
                            )
                        }
                    }
                }
                if !problem.isEmpty {
                    Text(problem).foregroundStyle(P.danger).font(.system(size: 13))
                }
                BigButton(text: "Guardar", primary: true) {
                    state.adjustScore(cur)
                    dismiss()
                }
                .disabled(!problem.isEmpty)
                .opacity(problem.isEmpty ? 1 : 0.4)
                SmallButton(text: "Cancelar") { dismiss() }
            }
            .padding(18)
        }
        .background(P.overlay.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

/// Casilla con − valor + del diálogo de ajustar marcador.
private struct Stepper2: View {
    let text: String
    let color: Color
    let canDown: Bool
    let canUp: Bool
    let onDown: () -> Void
    let onUp: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            stepButton("−", canDown, onDown)
            Text(text)
                .foregroundStyle(color)
                .font(.system(size: 24, weight: .heavy).monospacedDigit())
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            stepButton("+", canUp, onUp)
        }
        .padding(4)
        .background(P.fieldBg)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(P.line, lineWidth: 1))
    }

    private func stepButton(_ label: String, _ enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .foregroundStyle(P.txt)
                .font(.system(size: 22, weight: .bold))
                .frame(width: 42, height: 42)
                .background(P.panel2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
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
