import SwiftUI

struct ActionsDashboardTile: View {
    let onAction: (QuickAction) -> Void

    var body: some View {
        NotchTile("Actions", systemImage: "bolt.fill") {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                grid
                Spacer(minLength: 0)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 10) {
            ForEach(QuickAction.allCases) { action in
                ActionButton(action: action) { onAction(action) }
            }
        }
    }
}

/// Monochrome at rest so six actions don't read as a carnival; each action's
/// own accent colour surfaces only on hover, as a quiet halo behind the glyph.
struct ActionButton: View {
    @Environment(\.notchTokens) private var tokens
    let action: QuickAction
    let onTap: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous)
                        .fill(hovering ? action.accent.opacity(0.22) : .white.opacity(0.05))
                    RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous)
                        .strokeBorder(hovering ? action.accent.opacity(0.40) : .white.opacity(0.08),
                                      lineWidth: 0.75)
                    Image(systemName: action.systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(hovering ? action.accent : tokens.textSecondary)
                }
                .frame(width: 28, height: 28)
                Text(action.label)
                    .font(tokens.captionFont)
                    .foregroundStyle(hovering ? tokens.textPrimary : tokens.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(NotchPressableStyle())
        .onHover { hovering = $0 }
        .help(action.label)
        .animation(tokens.hoverAnimation, value: hovering)
    }
}
