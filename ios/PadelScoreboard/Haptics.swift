import UIKit

/// Vibración de confirmación al apuntar. En Android se pide por milisegundos;
/// aquí se traduce al golpe háptico equivalente del iPhone.
enum Haptics {

    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notice = UINotificationFeedbackGenerator()

    static func prepare() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
    }

    /// `ms` es la duración que pedía la versión Android: 25 punto, 45 juego,
    /// 80 set, 120 partido.
    static func buzz(_ ms: Int) {
        switch ms {
        case ..<30:
            light.impactOccurred()
            light.prepare()
        case ..<60:
            medium.impactOccurred()
            medium.prepare()
        case ..<100:
            heavy.impactOccurred()
            heavy.prepare()
        default:
            notice.notificationOccurred(.success)
            notice.prepare()
        }
    }
}
