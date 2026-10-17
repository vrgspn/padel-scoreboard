import SwiftUI

/// Aviso grande centrado: cambio de lado, tie-break, set o partido.
struct BannerOverlay: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        if let banner = state.banner {
            VStack(spacing: 6) {
                Text(banner.big)
                    .foregroundStyle(P.txt)
                    .font(.system(size: 28, weight: .heavy))
                    .multilineTextAlignment(.center)
                if !banner.sub.isEmpty {
                    Text(banner.sub)
                        .foregroundStyle(P.dim)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(P.overlay)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(P.line, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 24, y: 8)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
            .allowsHitTesting(false)
        }
    }
}

/// Mensaje breve en la parte inferior.
struct ToastOverlay: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        if let text = state.toast {
            Text(text)
                .foregroundStyle(P.txt)
                .font(.system(size: 14))
                .lineLimit(1)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(P.overlay)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(P.line, lineWidth: 1))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }
}

/// Aviso del mando de un botón: cuántas pulsaciones llevas y qué va a pasar.
struct BurstOverlay: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        if state.burstCount > 0 {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < state.burstCount ? P.teamA : Color(hex: 0x334155))
                            .frame(width: 18, height: 18)
                    }
                }
                Text(state.burstText(state.burstCount))
                    .foregroundStyle(P.txt)
                    .font(.system(size: 15, weight: .semibold))
                    .multilineTextAlignment(.center)
                BurstBar(windowMs: state.cfg.burstWindowMs, trigger: state.burstId)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .background(P.overlay)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(P.line, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 24, y: 8)
            .allowsHitTesting(false)
        }
    }
}

/// Va de 1 a 0 durante la espera entre pulsaciones del mando.
private struct BurstBar: View {
    let windowMs: Double
    let trigger: Double

    @State private var progress: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(hex: 0x24324D))
                Capsule()
                    .fill(P.teamA)
                    .frame(width: max(geo.size.width * progress, 2))
            }
        }
        .frame(width: 190, height: 5)
        .onAppear { restart() }
        .onChange(of: trigger) { _, _ in restart() }
    }

    private func restart() {
        progress = 1
        withAnimation(.linear(duration: windowMs / 1000)) { progress = 0 }
    }
}

/// Se muestra al acabar el partido, con el resultado y el tiempo jugado.
struct WinnerOverlay: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        let match = state.match
        if match.finished && match.winner >= 0 {
            ZStack {
                Color(hex: 0x060A13).opacity(0.93).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        Text("🏆").font(.system(size: 64))
                        Spacer().frame(height: 8)
                        Text(state.cfg.names[match.winner])
                            .foregroundStyle(P.txt)
                            .font(.system(size: 32, weight: .heavy))
                            .multilineTextAlignment(.center)
                        Spacer().frame(height: 10)
                        Text(state.scoreLine())
                            .foregroundStyle(P.dim)
                            .font(.system(size: 22))
                            .multilineTextAlignment(.center)
                        Spacer().frame(height: 6)
                        Text(winnerLine(match))
                            .foregroundStyle(P.dim)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                        Spacer().frame(height: 20)
                        BigButton(text: "Nuevo partido", primary: true) { state.setScreen(.setup) }
                        BigButton(text: "Deshacer el último punto") { state.undo() }
                    }
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                    .padding(24)
                }
            }
        }
    }

    private func winnerLine(_ match: Match) -> String {
        let names = state.cfg.players[match.winner].joined(separator: " y ")
        let mins = Int(match.elapsed / 60000)
        return names + (mins > 0 ? " · \(mins) min" : "")
    }
}
