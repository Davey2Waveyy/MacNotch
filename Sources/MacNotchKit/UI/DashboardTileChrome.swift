import SwiftUI

// MARK: - Theme

/// Shared visual constants so the dashboard and wide-bar layouts stay in sync.
enum NotchTheme {
    static let tileCornerRadius: CGFloat = 16
    static let tileFill     = Color.white.opacity(0.09)
    static let tileStroke   = Color.white.opacity(0.14)
    static let hairline     = Color.white.opacity(0.10)
    static let accent       = Color(red: 0.36, green: 0.78, blue: 1)

    // Gradient helpers used inside DashboardTileSurface
    static func tileFillGradient(hovered: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(hovered ? 0.17 : 0.13),
                Color.white.opacity(hovered ? 0.06 : 0.045)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func tileStrokeGradient(hovered: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(hovered ? 0.44 : 0.30),
                Color.white.opacity(hovered ? 0.10 : 0.07)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Tile surface

/// Rounded card surface that frames each dashboard widget.
///
/// Visual language:
/// • Gradient fill  — lighter at top, darker at bottom — simulates a light source above.
/// • Gradient stroke — top edge is bright (specular rim), fades toward the bottom.
/// • Inner specular crescent — thin bright band just inside the top edge.
/// • Depth shadow   — subtle downward shadow so tiles float above the glass.
/// • Hover lift     — brightness + scale micro-interaction matching macOS Control Center.
struct DashboardTileSurface: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: NotchTheme.tileCornerRadius, style: .continuous)
                    .fill(NotchTheme.tileFillGradient(hovered: isHovered))
            )
            .overlay(
                RoundedRectangle(cornerRadius: NotchTheme.tileCornerRadius, style: .continuous)
                    .strokeBorder(NotchTheme.tileStrokeGradient(hovered: isHovered), lineWidth: 1)
            )
            // Inner specular crescent at the top of each tile
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(isHovered ? 0.16 : 0.11), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)
                .clipShape(RoundedRectangle(cornerRadius: NotchTheme.tileCornerRadius, style: .continuous))
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            }
            // Depth: tile floats above the glass panel
            .shadow(color: .black.opacity(0.38), radius: 12, x: 0, y: 6)
            // Hover: soft white ambient glow
            .shadow(color: .white.opacity(isHovered ? 0.07 : 0), radius: 18, x: 0, y: 0)
            .scaleEffect(isHovered ? 1.014 : 1, anchor: .center)
            .animation(.spring(response: 0.22, dampingFraction: 0.76), value: isHovered)
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
