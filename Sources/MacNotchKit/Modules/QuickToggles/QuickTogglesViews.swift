import SwiftUI

struct QuickTogglesView: View {
    @ObservedObject var state: QuickTogglesModule.StateBox
    weak var controller: QuickTogglesModule?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("QUICK TOGGLES")
                .font(.system(size: 9, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.45))
            grid
        }
    }

    private var grid: some View {
        HStack(spacing: 8) {
            ToggleChip(icon: state.darkMode ? "moon.fill" : "moon",
                       label: "Dark", on: state.darkMode) { controller?.toggleDarkMode() }
            ToggleChip(icon: state.muted ? "speaker.slash.fill" : "speaker.wave.2",
                       label: state.muted ? "Muted" : "Audio", on: state.muted) { controller?.toggleMute() }
            ToggleChip(icon: state.caffeinated ? "cup.and.saucer.fill" : "cup.and.saucer",
                       label: "Awake", on: state.caffeinated) { controller?.toggleCaffeinate() }
            ToggleChip(icon: state.dndActive ? "bell.slash.fill" : "bell.slash", label: "DND", on: state.dndActive) { controller?.toggleDoNotDisturb() }
        }
    }
}

struct QuickTogglesDashboardTile: View {
    @ObservedObject var state: QuickTogglesModule.StateBox
    weak var controller: QuickTogglesModule?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Quick toggles", systemImage: "switch.2")
            Spacer(minLength: 6)
            grid
            Spacer(minLength: 0)
            Text(activeSummary)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var activeSummary: String {
        var on: [String] = []
        if state.darkMode { on.append("Dark") }
        if state.muted { on.append("Muted") }
        if state.caffeinated { on.append("Awake") }
        return on.isEmpty ? "Nothing on" : on.joined(separator: " · ")
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ToggleChip(icon: state.darkMode ? "moon.fill" : "moon",
                       label: "Dark", on: state.darkMode) { controller?.toggleDarkMode() }
            ToggleChip(icon: state.muted ? "speaker.slash.fill" : "speaker.wave.2",
                       label: state.muted ? "Muted" : "Audio", on: state.muted) { controller?.toggleMute() }
            ToggleChip(icon: state.caffeinated ? "cup.and.saucer.fill" : "cup.and.saucer",
                       label: "Awake", on: state.caffeinated) { controller?.toggleCaffeinate() }
            ToggleChip(icon: state.dndActive ? "bell.slash.fill" : "bell.slash", label: "DND", on: state.dndActive) { controller?.toggleDoNotDisturb() }
        }
    }
}

struct ToggleChip: View {
    @Environment(\.notchTokens) private var tokens
    let icon: String
    let label: String
    let on: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(on ? tokens.accent : .white.opacity(0.85))
                Text(label)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(.white.opacity(on ? 0.95 : 0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(on ? tokens.accent.opacity(0.18) : (hovering ? .white.opacity(0.06) : .white.opacity(0.025)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(on ? tokens.accent.opacity(0.45) : .white.opacity(hovering ? 0.16 : 0.07),
                                  lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
        .animation(.easeOut(duration: 0.15), value: on)
    }
}
