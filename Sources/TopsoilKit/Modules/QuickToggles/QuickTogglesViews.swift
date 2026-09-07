import SwiftUI

struct QuickTogglesView: View {
    @Environment(\.notchTokens) private var tokens
    @ObservedObject var state: QuickTogglesModule.StateBox
    weak var controller: QuickTogglesModule?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("QUICK TOGGLES")
                .font(tokens.caption2Font)
                .tracking(0.9)
                .foregroundStyle(tokens.textTertiary)
            grid
        }
    }

    private var grid: some View {
        HStack(spacing: 8) {
            toggleChips
        }
    }

    @ViewBuilder
    private var toggleChips: some View {
        ToggleChip(icon: state.darkMode ? "moon.fill" : "moon",
                   label: "Dark", on: state.darkMode) { controller?.toggleDarkMode() }
        ToggleChip(icon: state.muted ? "speaker.slash.fill" : "speaker.wave.2",
                   label: state.muted ? "Muted" : "Audio", on: state.muted) { controller?.toggleMute() }
        ToggleChip(icon: state.caffeinated ? "cup.and.saucer.fill" : "cup.and.saucer",
                   label: "Awake", on: state.caffeinated) { controller?.toggleCaffeinate() }
        ToggleChip(icon: state.dndActive ? "bell.slash.fill" : "bell.slash",
                   label: "DND", on: state.dndActive) { controller?.toggleDoNotDisturb() }
    }
}

struct QuickTogglesDashboardTile: View {
    @ObservedObject var state: QuickTogglesModule.StateBox
    weak var controller: QuickTogglesModule?

    var body: some View {
        NotchTile("Quick Toggles", systemImage: "switch.2") {
            grid
        } trailing: {
            Text(activeSummary)
        }
    }

    private var activeSummary: String {
        let count = [state.darkMode, state.muted, state.caffeinated, state.dndActive]
            .filter { $0 }.count
        return count == 0 ? "ALL OFF" : "\(count) ON"
    }

    private var grid: some View {
        // Two rows that stretch to fill the tile so toggles form an even 2×2
        // field instead of floating in dead space.
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ToggleChip(icon: state.darkMode ? "moon.fill" : "moon",
                           label: "Dark", on: state.darkMode, fillsHeight: true) { controller?.toggleDarkMode() }
                ToggleChip(icon: state.muted ? "speaker.slash.fill" : "speaker.wave.2",
                           label: state.muted ? "Muted" : "Audio", on: state.muted, fillsHeight: true) { controller?.toggleMute() }
            }
            HStack(spacing: 8) {
                ToggleChip(icon: state.caffeinated ? "cup.and.saucer.fill" : "cup.and.saucer",
                           label: "Awake", on: state.caffeinated, fillsHeight: true) { controller?.toggleCaffeinate() }
                ToggleChip(icon: state.dndActive ? "bell.slash.fill" : "bell.slash",
                           label: "DND", on: state.dndActive, fillsHeight: true) { controller?.toggleDoNotDisturb() }
            }
        }
    }
}

struct ToggleChip: View {
    @Environment(\.notchTokens) private var tokens
    let icon: String
    let label: String
    let on: Bool
    var fillsHeight: Bool = false
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(on ? tokens.accent : tokens.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
                Text(label)
                    .font(tokens.captionFont)
                    .foregroundStyle(on ? tokens.textPrimary : tokens.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: fillsHeight ? .infinity : nil)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous)
                    .fill(on ? tokens.accent.opacity(0.16) : .white.opacity(hovering ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous)
                    .strokeBorder(on ? tokens.accent.opacity(0.40) : .white.opacity(hovering ? 0.16 : 0.07),
                                  lineWidth: 0.75)
            )
            .contentShape(RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous))
        }
        .buttonStyle(NotchPressableStyle())
        .onHover { hovering = $0 }
        .animation(tokens.hoverAnimation, value: hovering)
        .animation(tokens.hoverAnimation, value: on)
        .accessibilityLabel("\(label) \(on ? "on" : "off")")
    }
}

/// Bare press feedback (scale only) for controls that draw their own chrome.
struct NotchPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        NotchPressableBody(configuration: configuration)
    }
}

private struct NotchPressableBody: View {
    @Environment(\.notchTokens) private var tokens
    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(tokens.pressAnimation, value: configuration.isPressed)
    }
}
