import SwiftUI

// MARK: - Button system
// One button language for the whole panel: every interactive control gets a
// hover state, a pressed state (scale + fill), and the shared corner radius.

enum NotchButtonProminence {
    case primary      // accent fill — the one action a tile wants you to take
    case soft         // neutral fill + hairline — default for everything else
    case ghost        // invisible until hovered — toolbars, footers, chrome
    case destructive  // reserved for remove/stop-and-lose-something actions
}

struct NotchPillButtonStyle: ButtonStyle {
    var prominence: NotchButtonProminence = .soft

    func makeBody(configuration: Configuration) -> some View {
        NotchPillBody(configuration: configuration, prominence: prominence)
    }
}

private struct NotchPillBody: View {
    @Environment(\.notchTokens) private var tokens
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyle.Configuration
    let prominence: NotchButtonProminence
    @State private var hovering = false

    var body: some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous)

        configuration.label
            .font(tokens.labelFont.weight(prominence == .primary ? .semibold : .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .frame(minHeight: 24)
            .background(shape.fill(fill(pressed: pressed)))
            .overlay(shape.strokeBorder(stroke, lineWidth: 0.75))
            .shadow(color: glow, radius: hovering ? 7 : 5, x: 0, y: 1)
            .scaleEffect(pressed ? 0.96 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(tokens.hoverAnimation, value: hovering)
            .animation(tokens.pressAnimation, value: pressed)
            .contentShape(shape)
            .onHover { hovering = $0 && isEnabled }
    }

    private var foreground: Color {
        switch prominence {
        case .primary: return Color.black.opacity(0.88)
        case .soft: return tokens.textPrimary
        case .ghost: return hovering ? tokens.textPrimary : tokens.textSecondary
        case .destructive: return hovering ? Color(red: 1, green: 0.55, blue: 0.55) : tokens.textSecondary
        }
    }

    private func fill(pressed: Bool) -> Color {
        switch prominence {
        case .primary:
            return tokens.accent.opacity(pressed ? 0.75 : (hovering ? 1.0 : 0.88))
        case .soft:
            return .white.opacity(pressed ? 0.16 : (hovering ? 0.12 : 0.08))
        case .ghost:
            return .white.opacity(pressed ? 0.12 : (hovering ? 0.07 : 0))
        case .destructive:
            return Color(red: 1, green: 0.35, blue: 0.35).opacity(pressed ? 0.30 : (hovering ? 0.22 : 0.10))
        }
    }

    private var stroke: Color {
        switch prominence {
        case .primary: return Color.black.opacity(0.88).opacity(0.18)
        case .soft: return .white.opacity(hovering ? 0.20 : 0.10)
        case .ghost: return .white.opacity(hovering ? 0.10 : 0)
        case .destructive: return Color(red: 1, green: 0.45, blue: 0.45).opacity(hovering ? 0.45 : 0.25)
        }
    }

    private var glow: Color {
        guard prominence == .primary else { return .clear }
        return .clear
    }
}

extension ButtonStyle where Self == NotchPillButtonStyle {
    static var notchPrimary: NotchPillButtonStyle { NotchPillButtonStyle(prominence: .primary) }
    static var notchSoft: NotchPillButtonStyle { NotchPillButtonStyle(prominence: .soft) }
    static var notchGhost: NotchPillButtonStyle { NotchPillButtonStyle(prominence: .ghost) }
    static var notchDestructive: NotchPillButtonStyle { NotchPillButtonStyle(prominence: .destructive) }
}

// MARK: - Icon buttons

/// Square icon control: quiet at rest, soft fill on hover, sinks on press.
/// The hit target is padded to at least 24×24 regardless of visual size.
struct NotchIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    var size: CGFloat = 24
    var iconSize: CGFloat = 11
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                // Glyph swaps (play→pause, pin→pin.fill) morph instead of popping.
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(NotchIconButtonStyle(size: size, isActive: isActive))
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}

struct NotchIconButtonStyle: ButtonStyle {
    var size: CGFloat = 24
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        NotchIconBody(configuration: configuration, size: size, isActive: isActive)
    }
}

private struct NotchIconBody: View {
    @Environment(\.notchTokens) private var tokens
    @Environment(\.isEnabled) private var isEnabled
    let configuration: ButtonStyle.Configuration
    let size: CGFloat
    let isActive: Bool
    @State private var hovering = false

    var body: some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous)

        configuration.label
            .foregroundStyle(iconColor)
            .frame(width: size, height: size)
            .background(shape.fill(fill(pressed: pressed)))
            .scaleEffect(pressed ? 0.92 : 1)
            .opacity(isEnabled ? 1 : 0.35)
            .animation(tokens.hoverAnimation, value: hovering)
            .animation(tokens.pressAnimation, value: pressed)
            // Pad the tap target to at least 24pt without growing the visuals.
            .contentShape(Rectangle().inset(by: min(0, (size - 24) / 2)))
            .onHover { hovering = $0 && isEnabled }
    }

    private var iconColor: Color {
        if isActive { return tokens.textPrimary }
        return hovering ? tokens.textPrimary : tokens.textTertiary
    }

    private func fill(pressed: Bool) -> Color {
        if pressed { return .white.opacity(0.14) }
        if isActive { return .white.opacity(0.12) }
        return .white.opacity(hovering ? 0.08 : 0)
    }
}
