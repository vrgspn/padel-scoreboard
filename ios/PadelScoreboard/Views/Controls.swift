import SwiftUI

/// Tarjeta gris con título, como las secciones de la versión web.
struct CardBox<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: title)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(P.panel)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(P.line, lineWidth: 1)
        )
        .padding(.bottom, 12)
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .foregroundStyle(P.dim)
            .font(.system(size: 12, weight: .bold))
            .kerning(1.4)
            .frame(minHeight: 22, alignment: .leading)
    }
}

/// Fila con interruptor; se puede pulsar en toda la fila.
struct SwitchRow: View {
    let title: String
    var subtitle: String = ""
    let isOn: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .foregroundStyle(P.txt)
                        .font(.system(size: 15, weight: .semibold))
                        .multilineTextAlignment(.leading)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .foregroundStyle(P.dim)
                            .font(.system(size: 12))
                            .lineSpacing(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("", isOn: Binding(get: { isOn }, set: { onChange($0) }))
                    .labelsHidden()
                    .tint(P.teamA)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { onChange(!isOn) }

            Rectangle().fill(P.line).frame(height: 1)
        }
    }
}

/// Grupo de botones donde sólo uno queda elegido.
struct Segmented<T: Equatable>: View {
    let options: [(String, T)]
    let selected: T
    let onPick: (T) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                let isSelected = option.1 == selected
                Button {
                    onPick(option.1)
                } label: {
                    Text(option.0)
                        .foregroundStyle(isSelected ? P.txt : P.dim)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(isSelected ? P.panel2 : P.fieldBg)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(isSelected ? P.pickBorder : P.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Botón de elección única dentro de una rejilla (por ejemplo, quién saca primero).
struct PickButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .foregroundStyle(isSelected ? P.txt : P.dim)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isSelected ? P.panel2 : P.fieldBg)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(isSelected ? P.pickBorder : P.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Campo de texto con etiqueta. Lo escrito se aplica al momento.
struct FieldBox: View {
    let label: String
    let text: String
    let onChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .foregroundStyle(P.dim)
                .font(.system(size: 13))
            TextField("", text: Binding(get: { text }, set: { onChange($0) }))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .submitLabel(.done)
                .foregroundStyle(P.txt)
                .font(.system(size: 16))
                .tint(P.teamA)
                .padding(.horizontal, 12)
                .frame(minHeight: 50)
                .background(P.fieldBg)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(P.line, lineWidth: 1)
                )
        }
    }
}

/// Botón ancho de la parte baja de las pantallas.
struct BigButton: View {
    let text: String
    var primary: Bool = false
    var danger: Bool = false
    let action: () -> Void

    private var background: Color {
        if primary { return P.teamA }
        if danger { return Color(hex: 0x3F1D1D) }
        return P.panel
    }

    private var foreground: Color {
        if primary { return Color(hex: 0x06281B) }
        if danger { return Color(hex: 0xFCA5A5) }
        return P.txt
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .foregroundStyle(foreground)
                .font(.system(size: 17, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(primary ? background : P.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

/// Botón mediano de una fila.
struct SmallButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .foregroundStyle(P.txt)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(P.panel)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(P.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct Help: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .foregroundStyle(P.dim)
            .font(.system(size: 12.5))
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
