import SwiftUI

/// Full-width horizontal strip shown along the top of the screen.
/// Modules opt in by implementing `wideBarView()`. Clicking the trailing
/// chevron returns to the dashboard.
struct WideBarLayoutView: View {
    let modules: [any NotchModule]
    let size: CGSize
    let onSwitchMode: (ExpansionMode) -> Void

    var body: some View {
        HStack(spacing: 14) {
            ForEach(barEntries, id: \.id) { entry in
                entry.view
            }

            Spacer(minLength: 0)

            Button {
                onSwitchMode(.dashboard)
            } label: {
                Image(systemName: "rectangle.compress.vertical")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .help("Back to dashboard")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .frame(width: size.width, height: size.height, alignment: .leading)
    }

    private var barEntries: [(id: String, view: AnyView)] {
        modules.compactMap { module in
            guard let view = module.wideBarView() else { return nil }
            return (module.id, view)
        }
    }
}
