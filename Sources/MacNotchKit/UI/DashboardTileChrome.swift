import SwiftUI

/// Shared visual constants so the dashboard and wide-bar layouts stay in sync.
enum NotchTheme {
    static let tileCornerRadius: CGFloat = 12
    static let tileFill = Color.white.opacity(0.09)
    static let tileStroke = Color.white.opacity(0.14)
    static let hairline = Color.white.opacity(0.10)
    static let accent = Color(red: 0.36, green: 0.78, blue: 1)
}

/// The rounded card surface that frames a single dashboard widget: a subtle
/// translucent fill plus a 1px inner stroke so each tile reads as its own panel
/// against the black notch chrome.
struct DashboardTileSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: NotchTheme.tileCornerRadius, style: .continuous)
                    .fill(NotchTheme.tileFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: NotchTheme.tileCornerRadius, style: .continuous)
                    .strokeBorder(NotchTheme.tileStroke, lineWidth: 1)
            )
    }
}

extension View {
    func dashboardTileSurface() -> some View {
        modifier(DashboardTileSurface())
    }
}

/// Small caps header shown at the top of every dashboard tile so the
/// horizontal layout reads as a row of labelled widgets.
struct TileHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .semibold))
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white.opacity(0.5))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One labelled item in the full-width wide-bar strip: an icon plus a short
/// status string, styled to sit on the dark notch chrome.
struct WideBarItem<Trailing: View>: View {
    let systemImage: String
    let text: String
    @ViewBuilder var trailing: () -> Trailing

    init(systemImage: String, text: String, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
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
