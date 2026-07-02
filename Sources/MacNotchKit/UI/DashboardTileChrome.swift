import SwiftUI

// MARK: - Tile surface

/// Flat surface that frames each dashboard widget without making it feel like a
/// separate floating bubble inside the notch.
struct DashboardTileSurface: ViewModifier {
    @Environment(\.notchTokens) private var tokens
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: tokens.tileCornerRadius, style: .continuous)
                    .fill(tokens.tileFillTint.opacity(tokens.tileFillOpacity + (isHovered ? 0.025 : 0)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: tokens.tileCornerRadius, style: .continuous)
                    .strokeBorder(hoveredStrokeColor, lineWidth: 0.75)
            )
            .animation(tokens.hoverAnimation, value: isHovered)
            .onHover { isHovered = $0 }
    }

    /// Same base color as `tileStrokeColor` (accent for terminal, else white),
    /// with hover raising the opacity by +0.09 over the resting value.
    private var hoveredStrokeColor: Color {
        let isTerminal = tokens.fontDesign == .monospaced
        let base = isTerminal ? tokens.accent : Color.white
        var opacity = isTerminal ? tokens.strokeOpacity + 0.10 : tokens.strokeOpacity
        if isHovered { opacity += 0.09 }
        return base.opacity(opacity)
    }
}

extension View {
    func dashboardTileSurface() -> some View {
        modifier(DashboardTileSurface())
    }
}

// MARK: - Tile header

/// Small header shown at the top of every dashboard tile.
/// The icon uses the accent colour so each tile reads as a distinct labelled widget.
struct TileHeader: View {
    @Environment(\.notchTokens) private var tokens
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tokens.accent)
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold, design: tokens.fontDesign))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.55))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Wide-bar components

/// One labelled item in the full-width wide-bar strip.
struct WideBarItem<Trailing: View>: View {
    @Environment(\.notchTokens) private var tokens
    let systemImage: String
    let text: String
    @ViewBuilder var trailing: () -> Trailing

    init(systemImage: String, text: String,
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.systemImage = systemImage
        self.text = text
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .medium, design: tokens.fontDesign))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 14)
            Text(text)
                .font(.system(size: 11, weight: .medium, design: tokens.fontDesign))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
            trailing()
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// Thin vertical separator placed between entries in the wide-bar strip.
struct WideBarDivider: View {
    @Environment(\.notchTokens) private var tokens

    var body: some View {
        Capsule()
            .fill(.white.opacity(tokens.strokeOpacity))
            .frame(width: 1, height: 18)
    }
}
