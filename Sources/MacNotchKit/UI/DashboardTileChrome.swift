import SwiftUI

// MARK: - Tile surface

/// Flat surface that frames each dashboard widget without making it feel like a
/// separate floating bubble inside the notch.
struct DashboardTileSurface: ViewModifier {
    @Environment(\.notchTokens) private var tokens
    @State private var isHovered = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: tokens.tileCornerRadius, style: .continuous)
        content
            .background(
                ZStack {
                    shape.fill(tokens.tileFillColor(hovered: isHovered))
                    // Faint top light so tiles read as machined surfaces, not flat fills.
                    shape.fill(
                        LinearGradient(
                            colors: [.white.opacity(isHovered ? 0.05 : 0.03), .clear],
                            startPoint: .top, endPoint: .center
                        )
                    )
                }
            )
            .overlay(shape.strokeBorder(tokens.tileStrokeColor(hovered: isHovered), lineWidth: 0.75))
            .animation(tokens.hoverAnimation, value: isHovered)
            .onHover { isHovered = $0 }
    }
}

extension View {
    func dashboardTileSurface() -> some View {
        modifier(DashboardTileSurface())
    }
}

// MARK: - Tile scaffold

/// Standard tile interior: header row, fixed 10pt gap, content filling the
/// rest. Every module tile uses this so baselines align across the dashboard.
struct NotchTile<Content: View, Trailing: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: () -> Content
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, systemImage: String,
         @ViewBuilder content: @escaping () -> Content,
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.systemImage = systemImage
        self.content = content
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TileHeader(title: title, systemImage: systemImage, trailing: trailing)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Tile header

/// Small header shown at the top of every dashboard tile.
/// The icon uses the accent colour so each tile reads as a distinct labelled
/// widget; the trailing slot carries a glanceable summary ("2 on", "3 files")
/// so status never dangles at the bottom of a tile.
struct TileHeader<Trailing: View>: View {
    @Environment(\.notchTokens) private var tokens
    let title: String
    let systemImage: String
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, systemImage: String,
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.systemImage = systemImage
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(tokens.accent.opacity(0.9))
            Text(title.uppercased())
                .font(tokens.caption2Font)
                .tracking(0.9)
                .foregroundStyle(tokens.textTertiary)
            Spacer(minLength: 0)
            trailing()
                .font(tokens.caption2Font)
                .foregroundStyle(tokens.textQuaternary)
        }
        .frame(height: 14)
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
                .foregroundStyle(tokens.textTertiary)
                .frame(width: 14)
            Text(text)
                .font(tokens.labelFont)
                .foregroundStyle(tokens.textPrimary)
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
