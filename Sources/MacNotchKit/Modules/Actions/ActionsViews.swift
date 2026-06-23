import SwiftUI

struct ActionsDashboardTile: View {
    let onAction: (QuickAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Actions", systemImage: "bolt.fill")
            Spacer(minLength: 6)
            grid
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
            ForEach(QuickAction.allCases) { action in
                ActionButton(action: action) { onAction(action) }
            }
        }
    }
}

struct ActionButton: View {
    let action: QuickAction
    let onTap: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(action.accent.opacity(hovering ? 0.30 : 0.20))
                        .frame(width: 26, height: 26)
                    Image(systemName: action.systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(action.accent)
                }
                Text(action.label)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hovering ? .white.opacity(0.05) : .clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(action.label)
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}
