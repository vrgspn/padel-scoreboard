import SwiftUI

/// Parejas, jugadores, saque inicial y formato. Lo escrito se aplica al momento.
struct SetupView: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        let cfg = state.cfg
        let match = state.match

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("🎾  Marcador de Pádel")
                    .foregroundStyle(P.txt)
                    .font(.system(size: 24, weight: .heavy))
                Spacer().frame(height: 4)
                Help("Configura el partido. Puedes dejarlo todo como está y empezar.")
                Spacer().frame(height: 14)

                CardBox(title: "Parejas") {
                    HStack(spacing: 10) {
                        FieldBox(label: "Pareja A", text: cfg.names[0]) { v in
                            state.updateCfg { var c = $0; c.names[0] = v; return c }
                        }
                        FieldBox(label: "Pareja B", text: cfg.names[1]) { v in
                            state.updateCfg { var c = $0; c.names[1] = v; return c }
                        }
                    }
                    HStack(spacing: 10) {
                        FieldBox(label: "Jugador 1 (A)", text: cfg.players[0][0]) { v in
                            state.updateCfg { var c = $0; c.players[0][0] = v; return c }
                        }
                        FieldBox(label: "Jugador 2 (A)", text: cfg.players[0][1]) { v in
                            state.updateCfg { var c = $0; c.players[0][1] = v; return c }
                        }
                    }
                    HStack(spacing: 10) {
                        FieldBox(label: "Jugador 3 (B)", text: cfg.players[1][0]) { v in
                            state.updateCfg { var c = $0; c.players[1][0] = v; return c }
                        }
                        FieldBox(label: "Jugador 4 (B)", text: cfg.players[1][1]) { v in
                            state.updateCfg { var c = $0; c.players[1][1] = v; return c }
                        }
                    }
                }

                CardBox(title: "Saque inicial") {
                    Help("El saque va rotando: A1 → B1 → A2 → B2 y vuelta a empezar.")
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            serveButton(cfg.players[0][0], team: 0, player: 0)
                            serveButton(cfg.players[0][1], team: 0, player: 1)
                        }
                        HStack(spacing: 6) {
                            serveButton(cfg.players[1][0], team: 1, player: 0)
                            serveButton(cfg.players[1][1], team: 1, player: 1)
                        }
                    }
                }

                CardBox(title: "Formato") {
                    Segmented(
                        options: [("1 set", 1), ("Al mejor de 3", 3), ("Al mejor de 5", 5)],
                        selected: cfg.bestOf
                    ) { v in
                        state.updateCfg { var c = $0; c.bestOf = v; return c }
                    }
                    SwitchRow(
                        title: "Punto de oro",
                        subtitle: "Con 40-40 el siguiente punto decide el juego. Sin punto de oro se juega con ventajas.",
                        isOn: cfg.golden
                    ) { v in state.updateCfg { var c = $0; c.golden = v; return c } }
                    SwitchRow(
                        title: "Tie-break a 6-6",
                        subtitle: "Desactivado, el set se gana por diferencia de 2 juegos.",
                        isOn: cfg.tiebreak
                    ) { v in state.updateCfg { var c = $0; c.tiebreak = v; return c } }
                    SwitchRow(
                        title: "Super tie-break en el set decisivo",
                        subtitle: "El último set se juega a 10 puntos en lugar de a juegos.",
                        isOn: cfg.superTb
                    ) { v in state.updateCfg { var c = $0; c.superTb = v; return c } }
                }

                VStack(spacing: 0) {
                    BigButton(text: "Empezar partido", primary: true) { state.startMatch() }
                    if match.startedAt > 0 && !match.finished {
                        BigButton(text: "Volver al partido en curso") {
                            state.screen = .match
                            state.showToast("Nombres actualizados")
                        }
                    }
                    BigButton(text: "Ajustes de sonido y mando ⚙") { state.screen = .settings }
                }
                Spacer().frame(height: 24)
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(16)
        }
        .background(P.bg)
        .scrollDismissesKeyboard(.interactively)
    }

    private func serveButton(_ name: String, team: Int, player: Int) -> some View {
        let selected = state.cfg.firstServeTeam == team && state.cfg.firstServePlayer == player
        return PickButton(label: name, isSelected: selected) {
            state.updateCfg { var c = $0; c.firstServeTeam = team; c.firstServePlayer = player; return c }
        }
    }
}
