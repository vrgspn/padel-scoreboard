import SwiftUI

@main
struct PadelScoreboardApp: App {

    @StateObject private var state = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { state.applyKeepAwake() }
                }
        }
    }
}

/// Única pantalla de la app, con los avisos por encima de todo.
struct RootView: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        ZStack {
            P.bg.ignoresSafeArea()

            switch state.screen {
            case .match: MatchView()
            case .setup: SetupView()
            case .settings: SettingsView()
            }

            if state.screen == .match { WinnerOverlay() }

            BannerOverlay()
            BurstOverlay()

            VStack {
                Spacer()
                ToastOverlay().padding(.bottom, 18)
            }

            // control de volumen invisible: deja recentrar el volumen del
            // sistema y evita el cartel de volumen encima del marcador
            HiddenVolumeView()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
        .animation(.easeOut(duration: 0.18), value: state.banner)
        .animation(.easeOut(duration: 0.18), value: state.toast)
    }
}
