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

            Button {
                onSwitchMode(.dashboard)
            } label: {
                Image(systemName: "rectangle.compress.vertical")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 28, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.white.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            .help("Back to dashboard")
        }
        .padding(.horizontal, 18)
        .frame(width: size.width, height: size.height, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(tokens.strokeOpacity))
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
