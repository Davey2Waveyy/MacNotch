import SwiftUI

/// Horizontal-tile expanded layout shown when the notch is clicked.
/// Modules opt in by implementing `dashboardTile()`; others are skipped.
/// Bottom toolbar lets the user switch between expansion modes.
struct DashboardLayoutView: View {
    let modules: [any NotchModule]
    let size: CGSize
    let activeMode: ExpansionMode
    let onSwitchMode: (ExpansionMode) -> Void

    private let toolbarHeight: CGFloat = 30
    private let tileSpacing: CGFloat = 10
    private let outerPadding: CGFloat = 14

    var body: some View {
        VStack(spacing: 0) {
            tilesRow
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Rectangle()
                .fill(NotchTheme.hairline)
                .frame(height: 1)
                .padding(.top, 10)
            modeToolbar
                .frame(height: toolbarHeight)
        }
        .padding(.horizontal, outerPadding)
        .padding(.top, outerPadding)
        .padding(.bottom, 6)
        .frame(width: size.width, height: size.height, alignment: .top)
    }

    private var tilesRow: some View {
        HStack(spacing: tileSpacing) {
            let tiles = modules.compactMap { module -> (id: String, view: AnyView)? in
                guard let tile = module.dashboardTile() else { return nil }
                return (module.id, tile)
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
