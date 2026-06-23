import SwiftUI

/// Horizontal-tile expanded layout shown when the notch is clicked.
/// Modules opt in by implementing `dashboardTile()`; others are skipped.
/// Tiles are shown 4 per page with < > arrows when there is more than one page.
struct DashboardLayoutView: View {
    let modules: [any NotchModule]
    let size: CGSize
    let activeMode: ExpansionMode
    var topInset: CGFloat = 0
    let onSwitchMode: (ExpansionMode) -> Void

    @State private var page = 0

    private let tilesPerPage = 4
    private let headerHeight: CGFloat = 18
    private let toolbarHeight: CGFloat = 30
    private let tileSpacing: CGFloat = 10
    private let outerPadding: CGFloat = 14
    private let arrowWidth: CGFloat = 20

    private var tiles: [(id: String, view: AnyView)] {
        modules.compactMap { module -> (id: String, view: AnyView)? in
            guard let tile = module.dashboardTile() else { return nil }
            return (module.id, tile)
        }
    }

    private var pageCount: Int {
        max(1, Int(ceil(Double(tiles.count) / Double(tilesPerPage))))
    }

    private var pageTiles: [(id: String, view: AnyView)] {
        let start = page * tilesPerPage
        let end = min(start + tilesPerPage, tiles.count)
        guard start < tiles.count else { return [] }
        return Array(tiles[start..<end])
    }

    var body: some View {
        VStack(spacing: 6) {
            header
                .frame(height: headerHeight)
            tilesRow
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Rectangle()
                .fill(NotchTheme.hairline)
                .frame(height: 1)
                .padding(.top, 6)
            modeToolbar
                .frame(height: toolbarHeight)
        }
        .padding(.horizontal, outerPadding)
        .padding(.top, topInset + 4)
        .padding(.bottom, 4)
        .frame(width: size.width, height: size.height, alignment: .top)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 5) {
            Text("Dashboard")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
            Text(modeLabel)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(NotchTheme.accent)
                .padding(.horizontal, 6)
                .padding(.vertical, 1.5)
                .background(Capsule().fill(NotchTheme.accent.opacity(0.16)))
            Spacer()
            if pageCount > 1 {
                pageDots
            }
            Text(Self.dateLabel())
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .padding(.leading, 8)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<pageCount, id: \.self) { i in
                Circle()
                    .fill(i == page ? Color.white.opacity(0.75) : Color.white.opacity(0.2))
                    .frame(width: i == page ? 5 : 4, height: i == page ? 5 : 4)
                    .animation(.easeOut(duration: 0.15), value: page)
            }
        }
    }

    private var modeLabel: String {
        switch activeMode {
        case .compact: return "QUICK"
        case .dashboard: return "QUICK"
        case .wideBar: return "WIDE"
        }
    }

    private static func dateLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: Date())
    }

    // MARK: - Tiles row with prev/next arrows

    private var tilesRow: some View {
        HStack(spacing: 0) {
            // Previous arrow
            navArrow(systemName: "chevron.left", enabled: page > 0) {
                withAnimation(.easeOut(duration: 0.18)) { page -= 1 }
            }

            // Tiles
            if tiles.isEmpty {
                Text("No dashboard tiles yet")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: tileSpacing) {
                    ForEach(pageTiles, id: \.id) { tile in
                        tile.view
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .dashboardTileSurface()
                    }
                    // Pad missing slots on the last page so tiles stay full-width
                    if pageTiles.count < tilesPerPage {
                        ForEach(0..<(tilesPerPage - pageTiles.count), id: \.self) { _ in
                            Color.clear
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: page > 0 ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: page > 0 ? .leading : .trailing).combined(with: .opacity)
                ))
            }

            // Next arrow
            navArrow(systemName: "chevron.right", enabled: page < pageCount - 1) {
                withAnimation(.easeOut(duration: 0.18)) { page += 1 }
            }
        }
    }

    private func navArrow(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(enabled ? .white.opacity(0.6) : .clear)
                .frame(width: arrowWidth, height: arrowWidth)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Mode toolbar

    private var modeToolbar: some View {
        HStack(spacing: 10) {
            Spacer()
            modeButton(.dashboard, system: "square.grid.2x2", label: "Dashboard")
            modeButton(.compact, system: "rectangle", label: "Compact")
            modeButton(.wideBar, system: "rectangle.split.3x1", label: "Wide Bar")
            Spacer()
        }
    }

    private func modeButton(_ mode: ExpansionMode, system: String, label: String) -> some View {
        Button {
            onSwitchMode(mode)
        } label: {
            Image(systemName: system)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(activeMode == mode ? Color.white : .white.opacity(0.45))
                .frame(width: 26, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(activeMode == mode ? .white.opacity(0.12) : .clear)
                )
        }
        .buttonStyle(.plain)
        .help(label)
    }
}
