import SwiftUI

struct SettingsView: View {
    @State private var settings: AppSettings
    private let titles: [String: String]
    private let loginItemIsEnabled: () -> Bool
    private let setLoginItemEnabled: (Bool) -> Bool
    private let onChange: (AppSettings) -> Void

    init(
        settings: AppSettings,
        titles: [String: String],
        loginItemIsEnabled: @escaping () -> Bool = LoginItem.isEnabled,
        setLoginItemEnabled: @escaping (Bool) -> Bool = LoginItem.setEnabled,
        onChange: @escaping (AppSettings) -> Void
    ) {
        _settings = State(initialValue: settings)
        self.titles = titles
        self.loginItemIsEnabled = loginItemIsEnabled
        self.setLoginItemEnabled = setLoginItemEnabled
        self.onChange = onChange
    }

    var body: some View {
        Form {
            Section("Modules") {
                List {
                    ForEach(settings.modules, id: \.id) { module in
                        Toggle(titles[module.id] ?? module.id, isOn: enabledBinding(for: module.id))
                    }
                    .onMove(perform: moveModules)
                }
                .frame(height: 140)
                Text("Drag to reorder. Changes apply to the notch immediately.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Expansion") {
                Picker("Click opens", selection: Binding(
                    get: { settings.defaultExpansionMode },
                    set: { mode in
                        settings.defaultExpansionMode = mode
                        onChange(settings)
                    }
                )) {
                    Text("Dashboard").tag(ExpansionMode.dashboard)
                    Text("Wide Bar").tag(ExpansionMode.wideBar)
                }
                Text("Hovering always shows the compact preview.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { isOn in
                        let operationSucceeded = setLoginItemEnabled(isOn)
                        let shouldPersist = SettingsLogic.applyLaunchAtLoginResult(
                            &settings,
                            requested: isOn,
                            operationSucceeded: operationSucceeded,
                            actualEnabled: loginItemIsEnabled()
                        )
                        guard shouldPersist else { return }
                        onChange(settings)
                    }
                ))
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 320)
    }

    private func enabledBinding(for id: String) -> Binding<Bool> {
        Binding(
            get: { settings.modules.first { $0.id == id }?.isEnabled ?? false },
            set: { isOn in
                SettingsLogic.toggle(&settings, id: id, on: isOn)
                onChange(settings)
            }
        )
    }

    private func moveModules(from offsets: IndexSet, to destination: Int) {
        SettingsLogic.reorder(&settings, fromOffsets: offsets, toOffset: destination)
        onChange(settings)
    }
}
