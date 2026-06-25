import SwiftUI

struct CustomizeDashboardTile: View {
    @ObservedObject var proxy: CustomizeModule.SettingsProxy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "MacNotch", systemImage: "gearshape.fill")
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
            var s = proxy.settings
            s.defaultExpansionMode = mode
            proxy.settings = s
            proxy.onChange(s)
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
                var s = proxy.settings
                if let i = s.modules.firstIndex(where: { $0.id == id }) {
                    s.modules[i].isEnabled = isOn
                }
                proxy.settings = s
                proxy.onChange(s)
            }
        )
    }

    private var launchBinding: Binding<Bool> {
        Binding(
            get: { proxy.settings.launchAtLogin },
            set: { isOn in
                var s = proxy.settings
                s.launchAtLogin = isOn
                proxy.settings = s
                proxy.onChange(s)
            }
        )
    }
}

/// Minimal checkbox-style toggle that works well at small sizes inside tiles.
private struct CompactCheckToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(configuration.isOn ? NotchTheme.accent : Color.white.opacity(0.08))
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
