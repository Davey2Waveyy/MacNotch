import SwiftUI

struct CustomizeDashboardTile: View {
    @ObservedObject var proxy: CustomizeModule.SettingsProxy
    @Environment(\.notchTokens) private var tokens

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Design Studio", systemImage: "slider.horizontal.3")
                .padding(.bottom, 8)

            Text("PRESET")
                .font(.system(size: 8, weight: .semibold, design: tokens.fontDesign))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.42))
                .padding(.bottom, 4)

            HStack(spacing: 5) {
                ForEach(AppearancePreset.launchPresets, id: \.self) { preset in
                    Button(shortLabel(for: preset)) {
                        proxy.update { $0.appearance.preset = preset }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 8.5, weight: .semibold, design: tokens.fontDesign))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(proxy.settings.appearance.preset == preset ? tokens.accent.opacity(0.20) : .white.opacity(0.06))
                    )
                    .accessibilityLabel("Use \(label(for: preset)) theme")
                    .accessibilityAddTraits(proxy.settings.appearance.preset == preset ? .isSelected : [])
                }
            }
            .padding(.bottom, 8)

            Text("ACCENT")
                .font(.system(size: 8, weight: .semibold, design: tokens.fontDesign))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.42))
                .padding(.bottom, 4)

            HStack(spacing: 6) {
                ForEach(AccentColorChoice.allCases, id: \.self) { choice in
                    let isSelected = proxy.settings.appearance.accentColor == choice
                    Button {
                        proxy.update { $0.appearance.accentColor = choice }
                    } label: {
                        Circle()
                            .fill(NotchTheme.accentColor(for: choice))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .strokeBorder(.white.opacity(0.9), lineWidth: isSelected ? 1.5 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Use \(accentName(for: choice)) accent")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.12))
                .padding(.bottom, 8)

            // Module toggles — exclude "customize" itself to avoid chicken-and-egg
            ScrollView(showsIndicators: false) {
                VStack(spacing: 3) {
                    ForEach(proxy.settings.modules.filter { $0.id != "customize" }, id: \.id) { module in
                        HStack(spacing: 6) {
                            Toggle(isOn: toggleBinding(for: module.id)) {
                                Text(proxy.titles[module.id] ?? module.id)
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.80))
                                    .lineLimit(1)
                            }
                            .toggleStyle(CompactCheckToggleStyle())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .background(Color.white.opacity(0.12))
                .padding(.vertical, 6)

            // Default click mode
            HStack(spacing: 0) {
                Text("CLICK")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(.white.opacity(0.40))
                    .frame(width: 36, alignment: .leading)
                modeChip(.dashboard, label: "Dashboard")
                modeChip(.wideBar,   label: "Wide Bar")
            }
            .padding(.bottom, 6)

            // Launch at login
            Toggle(isOn: launchBinding) {
                Text("Launch at login")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.70))
            }
            .toggleStyle(CompactCheckToggleStyle())
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Helpers

    private func modeChip(_ mode: ExpansionMode, label: String) -> some View {
        let active = proxy.settings.defaultExpansionMode == mode
        return Button(label) {
            proxy.update { $0.defaultExpansionMode = mode }
        }
        .buttonStyle(.plain)
        .font(.system(size: 9, weight: .semibold))
        .foregroundStyle(active ? Color.white : Color.white.opacity(0.40))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(active ? Color.white.opacity(0.14) : Color.clear)
        )
    }

    private func toggleBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { proxy.settings.modules.first { $0.id == id }?.isEnabled ?? false },
            set: { isOn in
                proxy.update { settings in
                    if let i = settings.modules.firstIndex(where: { $0.id == id }) {
                        settings.modules[i].isEnabled = isOn
                    }
                }
            }
        )
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { proxy.settings.launchAtLogin },
            set: { isOn in
                proxy.update { $0.launchAtLogin = isOn }
            }
        )
    }

    private func shortLabel(for preset: AppearancePreset) -> String {
        switch preset {
        case .studioGlass: return "Studio"
        case .minimalGraphite: return "Graphite"
        case .aurora: return "Aurora"
        case .terminal: return "Terminal"
        case .paper: return "Paper"
        }
    }

    private func label(for preset: AppearancePreset) -> String {
        switch preset {
        case .studioGlass: return "Studio Glass"
        case .minimalGraphite: return "Minimal Graphite"
        case .aurora: return "Aurora"
        case .terminal: return "Terminal"
        case .paper: return "Paper"
        }
    }

    private func accentName(for choice: AccentColorChoice) -> String {
        switch choice {
        case .cyan: return "Cyan"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .green: return "Green"
        case .amber: return "Amber"
        case .red: return "Red"
        }
    }
}

/// Minimal checkbox-style toggle that works well at small sizes inside tiles.
private struct CompactCheckToggleStyle: ToggleStyle {
    @Environment(\.notchTokens) private var tokens

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(configuration.isOn ? tokens.accent : Color.white.opacity(0.08))
                        .frame(width: 13, height: 13)
                    if configuration.isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.black)
                    }
                }
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}
