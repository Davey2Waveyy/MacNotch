import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: SettingsWindowModel
    @State private var selectedSection: SettingsSection = .general
    @State private var moduleQuery = ""
    private let titles: [String: String]
    private let loginItemIsEnabled: () -> Bool
    private let setLoginItemEnabled: (Bool) -> Bool
    private let onChange: (AppSettings) -> Void

    private var settings: AppSettings {
        get { model.settings }
        nonmutating set { model.settings = newValue }
    }

    init(
        model: SettingsWindowModel,
        titles: [String: String],
        loginItemIsEnabled: @escaping () -> Bool = LoginItem.isEnabled,
        setLoginItemEnabled: @escaping (Bool) -> Bool = LoginItem.setEnabled,
        onChange: @escaping (AppSettings) -> Void
    ) {
        self.model = model
        self.titles = titles
        self.loginItemIsEnabled = loginItemIsEnabled
        self.setLoginItemEnabled = setLoginItemEnabled
        self.onChange = onChange
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 25, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                    Text(NotchBrand.productName)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("A little space.\nA lot within reach.")
                        .font(.callout).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 18).padding(.top, 22)
                List(SettingsSection.allCases, selection: $selectedSection) { section in
                    Label(section.rawValue, systemImage: section.icon).tag(section)
                        .padding(.vertical, 5)
                }
                .listStyle(.sidebar)
                Text("Made for your Mac")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(18)
            }
            .frame(width: 190)
            .background(.quaternary.opacity(0.4))
            Divider()

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(selectedSection.rawValue).font(.system(size: 25, weight: .bold))
                    Text(selectedSection.subtitle).font(.callout).foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 8)
                Group {
                switch selectedSection {
                case .general:
                    generalSection
                case .modules:
                    modulesSection
                case .design:
                    DesignSettingsView(settings: $model.settings, onChange: onChange)
                case .privacy:
                    privacySection
                case .shortcuts:
                    shortcutsSection
                case .about:
                    aboutSection
                }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 760, idealWidth: 820, minHeight: 560, idealHeight: 620)
    }

    private var generalSection: some View {
        Form {
            Section("Workspace") {
                Picker("Workspace", selection: Binding(
                    get: { settings.activeWorkspaceProfileID ?? "custom" },
                    set: { id in
                        if let profile = WorkspaceProfile.defaults.first(where: { $0.id == id }) {
                            profile.apply(to: &settings)
                            onChange(settings)
                        }
                    }
                )) {
                    Text("Custom").tag("custom")
                    ForEach(WorkspaceProfile.defaults) { profile in
                        Text(profile.name).tag(profile.id)
                    }
                }
                Text("Switching a workspace applies its theme, modules, and default mode.")
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
                    Text("Compact").tag(ExpansionMode.compact)
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
    }

    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Find a module", text: $moduleQuery).textFieldStyle(.plain)
                    .accessibilityLabel("Search module library")
                if !moduleQuery.isEmpty {
                    Button { moduleQuery = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).accessibilityLabel("Clear module search")
                }
            }
            .padding(10).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 9))
            HStack {
                Text("\(settings.modules.filter(\.isEnabled).count) enabled")
                Spacer()
                Text(moduleQuery.isEmpty ? "Drag to reorder" : "Clear search to reorder")
            }
            .font(.caption).foregroundStyle(.secondary)
            List {
                ForEach(settings.modules.filter { module in
                    moduleQuery.isEmpty || "\(titles[module.id] ?? module.id) \(ModulePresentation.description(for: module.id))"
                        .localizedStandardContains(moduleQuery)
                }, id: \.id) { module in
                    HStack(spacing: 12) {
                        Image(systemName: ModulePresentation.icon(for: module.id))
                            .font(.system(size: 16)).foregroundStyle(Color.accentColor)
                            .frame(width: 34, height: 34)
                            .background(Color.accentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 9))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(titles[module.id] ?? module.id).font(.body.weight(.medium))
                            Text(ModulePresentation.description(for: module.id))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle(titles[module.id] ?? module.id, isOn: enabledBinding(for: module.id))
                            .labelsHidden().toggleStyle(.switch).controlSize(.small)
                    }
                    .padding(.vertical, 6)
                    .moveDisabled(!moduleQuery.isEmpty)
                }
                .onMove(perform: moveModules)
            }
            .listStyle(.inset)
            Text("Changes apply immediately. Disabled modules keep their saved data.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
    }

    private var privacySection: some View {
        Form {
            Section("Privacy") {
                Text(NotchBrand.affiliationDisclaimer)
                Text("Topsoil stores settings on this Mac and asks for permissions when a module needs them. Media controls use Automation; your schedule uses Calendar access.")
            }
        }
        .formStyle(.grouped)
    }

    private var shortcutsSection: some View {
        Form {
            Section("Shortcuts") {
                LabeledContent("Previous dashboard page", value: "⌘[")
                LabeledContent("Next dashboard page", value: "⌘]")
                LabeledContent("Clear tool search", value: "Esc")
            }
            Section("Around the notch") {
                LabeledContent("Preview your tools", value: "Hover over the notch")
                LabeledContent("Open your workspace", value: "Click the notch")
                LabeledContent("Keep the panel open", value: "Click the pin")
                LabeledContent("Move the panel", value: "Drag the grip")
                LabeledContent("Change pages", value: "Click a tab or swipe sideways")
                Text("Page shortcuts work while the Topsoil panel has keyboard focus.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private var aboutSection: some View {
        Form {
            Section("About") {
                Label(NotchBrand.productName, systemImage: "square.stack.3d.up.fill")
                    .font(.title2.bold())
                Text("Your music, tools, and next small task. Right where you need them.")
                    .foregroundStyle(.secondary)
                Text(NotchBrand.affiliationDisclaimer).font(.caption).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
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
        guard moduleQuery.isEmpty else { return }
        SettingsLogic.reorder(&settings, fromOffsets: offsets, toOffset: destination)
        onChange(settings)
    }
}
