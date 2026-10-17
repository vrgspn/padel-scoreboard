import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var state: AppState

    var body: some View {
        let cfg = state.cfg

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("⚙  Ajustes")
                    .foregroundStyle(P.txt)
                    .font(.system(size: 24, weight: .heavy))
                Spacer().frame(height: 4)
                Help("Sonido, mando a distancia, pantalla y partido.")
                Spacer().frame(height: 14)

                CardBox(title: "Sonido") {
                    SwitchRow(
                        title: "Cantar el marcador",
                        subtitle: "Dice el tanteo tras cada punto y quién gana cada juego, set y partido. Siempre empezando por quien saca, como en la pista.",
                        isOn: cfg.voice
                    ) { v in state.updateCfg { var c = $0; c.voice = v; return c } }
                    SwitchRow(
                        title: "Decir quién saca",
                        subtitle: "Añade «saca Ismael» después del tanteo.",
                        isOn: cfg.voiceServer
                    ) { v in state.updateCfg { var c = $0; c.voiceServer = v; return c } }
                    SwitchRow(
                        title: "Decir desde qué lado saca",
                        subtitle: "Añade «desde la derecha» o «desde la izquierda», según toque cuadro de derecha o de revés.",
                        isOn: cfg.voiceCourtSide
                    ) { v in state.updateCfg { var c = $0; c.voiceCourtSide = v; return c } }
                    SwitchRow(
                        title: "Avisar del cambio de lado",
                        subtitle: "Dice «cambio de lado» cuando toca cambiar de pista.",
                        isOn: cfg.voiceSwitch
                    ) { v in state.updateCfg { var c = $0; c.voiceSwitch = v; return c } }
                    SwitchRow(
                        title: "Vibrar al apuntar",
                        subtitle: "Confirmación táctil al sumar cada punto.",
                        isOn: cfg.vibrate
                    ) { v in state.updateCfg { var c = $0; c.vibrate = v; return c } }

                    Spacer().frame(height: 12)
                    Text("Velocidad de la voz")
                        .foregroundStyle(P.dim)
                        .font(.system(size: 13))
                    Segmented(
                        options: [("Lenta", 0.9), ("Normal", 1.05), ("Rápida", 1.3)],
                        selected: cfg.voiceRate
                    ) { v in state.updateCfg { var c = $0; c.voiceRate = v; return c } }
                    Spacer().frame(height: 10)
                    SmallButton(text: "▶  Probar voz") { state.speakTest() }
                }

                CardBox(title: "Mando de disparo (pulsador)") {
                    SwitchRow(
                        title: "Usar las teclas de volumen",
                        subtitle: "La app apunta el punto cuando tu pulsador sube o baja el volumen, y vuelve a dejar el volumen en su sitio.",
                        isOn: cfg.volumeKeys
                    ) { v in state.updateCfg { var c = $0; c.volumeKeys = v; return c } }
                    SwitchRow(
                        title: "Modo un solo botón",
                        subtitle: "Para pulsadores con un único botón: 1 pulsación = punto para quien saca · 2 pulsaciones = punto para quien resta · 3 pulsaciones = deshacer.",
                        isOn: cfg.oneButton
                    ) { v in state.updateCfg { var c = $0; c.oneButton = v; return c } }

                    Spacer().frame(height: 12)
                    Text("Espera entre pulsaciones")
                        .foregroundStyle(P.dim)
                        .font(.system(size: 13))
                    Segmented(
                        options: [("1,5 s", 1500.0), ("3 s", 3000.0), ("5 s", 5000.0), ("8 s", 8000.0)],
                        selected: cfg.burstWindowMs
                    ) { v in state.updateCfg { var c = $0; c.burstWindowMs = v; return c } }
                    Spacer().frame(height: 8)
                    Help(
                        "Tiempo que se espera otra pulsación antes de apuntar. Súbelo si tu pulsador tarda en responder; "
                        + "bájalo si quieres que el punto entre al instante. Con tres pulsaciones no se espera."
                    )
                    if !state.lastSignal.isEmpty {
                        Spacer().frame(height: 10)
                        Text("Última señal recibida: " + state.lastSignal)
                            .foregroundStyle(P.teamA)
                            .font(.system(size: 13))
                    }
                    Spacer().frame(height: 8)
                    Help(
                        "Sin el modo un solo botón, bajar volumen suma punto a la pareja A y subir volumen a la pareja B. "
                        + "Un toque en cada mitad de la pantalla también suma punto."
                    )
                }

                CardBox(title: "Pantalla") {
                    SwitchRow(
                        title: "Mantener pantalla encendida",
                        subtitle: "Evita que se apague durante el partido.",
                        isOn: cfg.keepAwake
                    ) { v in state.updateCfg { var c = $0; c.keepAwake = v; return c } }
                    SwitchRow(
                        title: "Intercambiar lados automáticamente",
                        subtitle: "Al cambiar de lado en la pista, las parejas también cambian en el marcador.",
                        isOn: cfg.autoSwap
                    ) { v in state.updateCfg { var c = $0; c.autoSwap = v; return c } }
                    SwitchRow(
                        title: "Avisar del cambio de lado",
                        subtitle: "Muestra un cartel cuando toca cambiar.",
                        isOn: cfg.sideAlert
                    ) { v in state.updateCfg { var c = $0; c.sideAlert = v; return c } }
                    Spacer().frame(height: 12)
                    SmallButton(text: "⇄  Intercambiar lados") { state.swapSides() }
                }

                VStack(spacing: 0) {
                    BigButton(text: "Volver al partido", primary: true) { state.setScreen(.match) }
                    BigButton(text: "Editar parejas y formato") { state.setScreen(.setup) }
                    BigButton(text: "Reiniciar marcador a 0", danger: true) {
                        state.resetScore()
                        state.setScreen(.match)
                    }
                }
                Spacer().frame(height: 24)
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding(16)
        }
        .background(P.bg)
    }
}
