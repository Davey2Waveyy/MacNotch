import SwiftUI

/// Horizontal-tile expanded layout shown when the notch is clicked.
/// Modules opt in by implementing `dashboardTile()`; others are skipped.
/// Top header carries the title; bottom toolbar switches expansion modes.
struct DashboardLayoutView: View {
    let modules: [any NotchModule]
    let size: CGSize
    let activeMode: ExpansionMode
    let onSwitchMode: (ExpansionMode) -> Void

    private let headerHeight: CGFloat = 18
    private let toolbarHeight: CGFloat = 30
    private let tileSpacing: CGFloat = 10
    private let outerPadding: CGFloat = 14

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
        .padding(.top, 8)
        .padding(.bottom, 4)
        .frame(width: size.width, height: size.height, alignment: .top)
    }

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
            Text(Self.dateLabel())
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
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

    /// Curated order for the default "Quick" dashboard view. Only tiles whose
    /// module ID appears here render in the dashboard, in this order — the
    /// rest of the dashboardTile() implementations are kept available for
    /// alternate dashboard pages we may add later.
    private static let dashboardOrder = ["quickToggles", "screenTime", "launcher", "actions"]

    private var tilesRow: some View {
        HStack(spacing: tileSpacing) {
            let available = Dictionary(uniqueKeysWithValues:
                modules.compactMap { module -> (String, AnyView)? in
                    guard let tile = module.dashboardTile() else { return nil }
                    return (module.id, tile)
                }
            )
            let tiles = Self.dashboardOrder.compactMap { id -> (id: String, view: AnyView)? in
                guard let view = available[id] else { return nil }
                return (id, view)
            }
            if tiles.isEmpty {
                Text("No dashboard tiles yet")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(tiles, id: \.id) { tile in
                    tile.view
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .dashboardTileSurface()
                }
            }
        }
    }

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
