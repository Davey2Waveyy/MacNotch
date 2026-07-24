import SwiftUI

/// Full-width horizontal strip shown along the top of the screen.
/// Modules opt in by implementing `wideBarView()`. Clicking the trailing
/// chevron returns to the dashboard.
struct WideBarLayoutView: View {
    @Environment(\.notchTokens) private var tokens
    let modules: [any NotchModule]
    let size: CGSize
    let onSwitchMode: (ExpansionMode) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(barEntries.enumerated()), id: \.element.id) { index, entry in
                if index > 0 {
                    WideBarDivider()
                }
                entry.view
            }

            Spacer(minLength: 12)

            NotchIconButton(
                systemName: "square.grid.2x2",
                accessibilityLabel: "Back to dashboard",
                size: 24, iconSize: 11
            ) { onSwitchMode(.dashboard) }
        }
        .padding(.horizontal, 18)
        .frame(width: size.width, height: size.height, alignment: .leading)
        .overlay(alignment: .bottom) {
            // Hairline that brightens toward the centre, echoing the notch above.
            LinearGradient(
                colors: [.clear, .white.opacity(tokens.strokeOpacity + 0.04), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 1)
        }
    }

    private var barEntries: [(id: String, view: AnyView)] {
        modules.compactMap { module in
            guard let view = module.wideBarView() else { return nil }
            return (module.id, view)
        }
    }
}
