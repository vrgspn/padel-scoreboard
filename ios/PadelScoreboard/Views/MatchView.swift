import SwiftUI

/// Pantalla del marcador: dos cuadros, uno por pareja.
struct MatchView: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()

            GeometryReader { geo in
                let portrait = geo.size.height > geo.size.width
                let w = geo.size.width
                let h = geo.size.height

                // tamaños calculados como en la web: proporcionales a la pantalla
                let numberSize: CGFloat = portrait
                    ? min(h * 0.30, w * 0.44)
                    : min(h * 0.52, w * 0.30)
                let nameSize: CGFloat = portrait
                    ? min(max(w * 0.055, 22), 40)
                    : min(max(h * 0.065, 18), 38)
                let playerSize: CGFloat = portrait
                    ? min(max(w * 0.055, 17), 34)
                    : min(max(h * 0.075, 16), 34)

                // el primer panel es el de la izquierda (o el de arriba en vertical)
                let order = state.match.swapped ? [1, 0] : [0, 1]

                if portrait {
                    VStack(spacing: 10) {
                        ForEach(order, id: \.self) { team in
                            TeamPanel(
                                team: team,
                                portrait: true,
                                rightSide: false,
                                numberSize: numberSize,
                                nameSize: nameSize,
                                playerSize: playerSize
                            )
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        ForEach(Array(order.enumerated()), id: \.offset) { index, team in
                            TeamPanel(
                                team: team,
                                portrait: false,
                                rightSide: index == 1,
                                numberSize: numberSize,
                                nameSize: nameSize,
                                playerSize: playerSize
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 10)

            Spacer().frame(height: 10)
        }
        .background(P.bg)
    }
}

private struct TeamPanel: View {

    @EnvironmentObject private var state: AppState

    let team: Int
    let portrait: Bool
    let rightSide: Bool
    let numberSize: CGFloat
    let nameSize: CGFloat
    let playerSize: CGFloat

    private var color: Color { P.team(team) }
    private var serving: (team: Int, player: Int) { Rules.serverOf(state.match, state.cfg) }
    private var isServingTeam: Bool { serving.team == team && !state.match.finished }

    var body: some View {
        panel
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(P.panel)
            .clipShape(RoundedRectangle(cornerRadius: P.radius, style: .continuous))
            .compositingGroup()
            // destello: entra rápido y se apaga en 1,5 s, sumando luz
            .keyframeAnimator(initialValue: 0.0, trigger: state.flashId) { view, value in
                view.overlay {
                    if state.flashTeam == team && value > 0.001 {
                        GeometryReader { geo in
                            RadialGradient(
                                stops: [
                                    .init(color: color, location: 0.0),
                                    .init(color: color.opacity(0.75), location: 0.42),
                                    .init(color: color.opacity(0.30), location: 0.70),
                                    .init(color: .clear, location: 0.88)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: max(geo.size.width, geo.size.height) * 0.75
                            )
                            .opacity(value)
                            .blendMode(.screen)
                        }
                        .allowsHitTesting(false)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: P.radius, style: .continuous))
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(1.0, duration: 0.27)
                    CubicKeyframe(0.75, duration: 0.555)
                    CubicKeyframe(0.0, duration: 0.675)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: P.radius, style: .continuous)
                    .stroke(isServingTeam ? color.opacity(0.55) : P.line, lineWidth: 1)
            )
            .overlay(alignment: portrait ? .topTrailing : .bottomTrailing) { stakeBadge }
            .contentShape(Rectangle())
            .onTapGesture { state.addPoint(team) }
    }

    // ------------------------------------------------------------- contenido

    @ViewBuilder
    private var panel: some View {
        if portrait {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        playerRow(0)
                        Spacer(minLength: 0)
                        playerRow(1)
                        Spacer(minLength: 0)
                        GamesRow(team: team)
                    }
                    .padding(.leading, 14)
                    .padding(.trailing, 4)
                    .padding(.vertical, 10)
                    .frame(width: geo.size.width * 0.42, alignment: .leading)

                    scoreBlock
                        .frame(width: geo.size.width * 0.58)
                }
            }
        } else {
            VStack(spacing: 0) {
                playerRow(0)
                scoreBlock.frame(maxHeight: .infinity)
                playerRow(1)
                Spacer().frame(height: 4)
                GamesRow(team: team)
            }
            .padding(10)
        }
    }

    private var scoreBlock: some View {
        let label = Rules.pointLabel(state.match, team)
        return VStack(spacing: 0) {
            Text(state.cfg.names[team].uppercased())
                .foregroundStyle(color)
                .font(.system(size: nameSize, weight: .heavy))
                .kerning(nameSize * 0.06)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
            Text(label)
                .foregroundStyle(P.txt)
                .font(.system(size: label == "AD" ? numberSize * 0.62 : numberSize, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private func playerRow(_ index: Int) -> some View {
        let isServer = isServingTeam && serving.player == index
        return HStack(spacing: 8) {
            if rightSide { Spacer(minLength: 0) }
            if !rightSide && isServer { Ball(size: playerSize * 0.72) }
            Text(state.cfg.players[team][index])
                .foregroundStyle(isServer ? P.txt : P.dim)
                .font(.system(size: playerSize, weight: isServer ? .bold : .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(rightSide ? .trailing : .leading)
            if rightSide && isServer { Ball(size: playerSize * 0.72) }
            if !rightSide { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: rightSide ? .trailing : .leading)
    }

    /// Aviso de punto de juego / break / set / partido, en la esquina.
    @ViewBuilder
    private var stakeBadge: some View {
        let match = state.match
        let base = Rules.stake(match, team, state.cfg)
        let stake = base.isEmpty
            ? ((!match.tiebreak && state.cfg.golden && match.pts[0] == 3 && match.pts[1] == 3) ? "Punto de oro" : "")
            : base
        if !stake.isEmpty {
            Text(stake.uppercased())
                .foregroundStyle(color)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color.opacity(0.18))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
                .padding(8)
                .allowsHitTesting(false)
        }
    }
}

/// Pelota de tenis que señala a quien saca.
struct Ball: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(hex: 0xEAFF79), P.ball, Color(hex: 0x9CBF16)],
                    center: .init(x: 0.35, y: 0.32),
                    startRadius: 0,
                    endRadius: size
                )
            )
            .frame(width: size, height: size)
    }
}

/// Juegos de cada set ya cerrado y los del set en curso.
private struct GamesRow: View {

    @EnvironmentObject private var state: AppState
    let team: Int

    var body: some View {
        let match = state.match
        HStack(spacing: 6) {
            ForEach(Array(match.sets.enumerated()), id: \.offset) { _, s in
                GameBox(
                    text: String(s.games(team)),
                    sup: s.hadTiebreak ? String(s.tb(team)) : nil,
                    color: s.games(team) > s.games(1 - team) ? P.txt : P.dim,
                    background: P.panel2
                )
            }
            if !match.finished {
                GameBox(
                    text: String(match.games[team]),
                    sup: nil,
                    color: P.team(team),
                    background: P.team(team).opacity(0.18)
                )
            }
        }
    }
}

private struct GameBox: View {
    let text: String
    let sup: String?
    let color: Color
    let background: Color

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(text)
                .foregroundStyle(color)
                .font(.system(size: 18, weight: .bold))
                .monospacedDigit()
            if let sup {
                Text(sup)
                    .foregroundStyle(P.dim)
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .frame(width: 34, height: 34)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
