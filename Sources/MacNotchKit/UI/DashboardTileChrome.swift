import SwiftUI

// MARK: - Theme

/// Shared visual constants so the dashboard and wide-bar layouts stay in sync.
enum NotchTheme {
    static let tileCornerRadius: CGFloat = 8
    static let tileFill     = Color.white.opacity(0.075)
    static let tileStroke   = Color.white.opacity(0.10)
    static let hairline     = Color.white.opacity(0.10)
    static let accent       = Color(red: 0.36, green: 0.78, blue: 1)

    // Kept for older tile callers that still want a subtle top-to-bottom tint.
    static func tileFillGradient(hovered: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(hovered ? 0.10 : 0.075),
                Color.white.opacity(hovered ? 0.08 : 0.060)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func tileStrokeGradient(hovered: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(hovered ? 0.18 : 0.10),
                Color.white.opacity(hovered ? 0.10 : 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Tile surface

/// Flat surface that frames each dashboard widget without making it feel like a
/// separate floating bubble inside the notch.
struct DashboardTileSurface: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: NotchTheme.tileCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(isHovered ? 0.095 : 0.070))
            )
            .overlay(
                RoundedRectangle(cornerRadius: NotchTheme.tileCornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(isHovered ? 0.18 : 0.09), lineWidth: 0.75)
            )
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .onHover { isHovered = $0 }
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
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(NotchTheme.accent)
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
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
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 14)
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
            trailing()
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

/// Thin vertical separator placed between entries in the wide-bar strip.
struct WideBarDivider: View {
    var body: some View {
        Capsule()
            .fill(NotchTheme.hairline)
            .frame(width: 1, height: 18)
    }
}
