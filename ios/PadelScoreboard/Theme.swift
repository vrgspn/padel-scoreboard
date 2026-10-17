import SwiftUI

/// Los mismos colores que la versión web y la app Android.
enum P {
    static let bg = Color(hex: 0x0B1220)
    static let panel = Color(hex: 0x141D31)
    static let panel2 = Color(hex: 0x1B2743)
    static let line = Color(hex: 0x2A3752)
    static let txt = Color(hex: 0xEEF3FF)
    static let dim = Color(hex: 0x93A2C4)
    static let teamA = Color(hex: 0x36D399)   // verde
    static let teamB = Color(hex: 0xFBBF24)   // amarillo
    static let danger = Color(hex: 0xF87171)
    static let ball = Color(hex: 0xCBE92F)

    static let overlay = Color(hex: 0x0F1A2E)
    static let fieldBg = Color(hex: 0x0C1424)
    static let pickBorder = Color(hex: 0x3F5A86)

    static func team(_ i: Int) -> Color { i == 0 ? teamA : teamB }

    static let radius: CGFloat = 18
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
