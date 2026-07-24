import Foundation

public struct ModuleSetting: Codable, Equatable, Sendable {
    public var id: String
    public var isEnabled: Bool

    public init(id: String, isEnabled: Bool) {
        self.id = id
        self.isEnabled = isEnabled
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var modules: [ModuleSetting]
    public var launchAtLogin: Bool
    /// Which mode a click on the notch opens into (hover always uses compact).
    public var defaultExpansionMode: ExpansionMode
    public var appearance: NotchAppearance
    public var activeWorkspaceProfileID: String?
    public var onboarding: OnboardingState
    public var isAquariumBatterySaverEnabled: Bool

    public init(modules: [ModuleSetting],
                launchAtLogin: Bool,
                defaultExpansionMode: ExpansionMode = .dashboard,
                appearance: NotchAppearance = .defaults,
                activeWorkspaceProfileID: String? = nil,
                onboarding: OnboardingState = .defaults,
                isAquariumBatterySaverEnabled: Bool = false) {
        self.modules = modules
        self.launchAtLogin = launchAtLogin
        self.defaultExpansionMode = defaultExpansionMode
        self.appearance = appearance
        self.activeWorkspaceProfileID = activeWorkspaceProfileID
        self.onboarding = onboarding
        self.isAquariumBatterySaverEnabled = isAquariumBatterySaverEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case modules, launchAtLogin, defaultExpansionMode, appearance, activeWorkspaceProfileID, onboarding, isAquariumBatterySaverEnabled
    }

    // Custom decoding so settings files written before `defaultExpansionMode`
    // existed still load (the field falls back to the default instead of failing
    // the whole decode and wiping the user's modules/login preference).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        modules = try container.decode([ModuleSetting].self, forKey: .modules)
        launchAtLogin = try container.decode(Bool.self, forKey: .launchAtLogin)
        defaultExpansionMode = try container.decodeIfPresent(
            ExpansionMode.self, forKey: .defaultExpansionMode) ?? .dashboard
        appearance = try container.decodeIfPresent(NotchAppearance.self, forKey: .appearance) ?? .defaults
        activeWorkspaceProfileID = try container.decodeIfPresent(String.self, forKey: .activeWorkspaceProfileID)
        onboarding = try container.decodeIfPresent(OnboardingState.self, forKey: .onboarding) ?? .defaults
        isAquariumBatterySaverEnabled = try container.decodeIfPresent(Bool.self, forKey: .isAquariumBatterySaverEnabled) ?? false
    }

    public static let defaults = AppSettings(
        modules: [
            // Page 1 — Utility pane (media, toggles, timers, actions, shelf).
            ModuleSetting(id: "media",        isEnabled: true),
            ModuleSetting(id: "quickToggles", isEnabled: true),
            ModuleSetting(id: "timers",       isEnabled: true),
            ModuleSetting(id: "actions",      isEnabled: true),
            ModuleSetting(id: "shelf",        isEnabled: true),
            // Page 2 — Code CLI (solo tile, fills full width).
            ModuleSetting(id: "code",         isEnabled: true),
            ModuleSetting(id: "commandPalette", isEnabled: true),
            // Page 3 — Stocks (solo tile, fills full width).
            ModuleSetting(id: "stocks",       isEnabled: true),
            // Page 4 — Garden
            ModuleSetting(id: "garden",       isEnabled: false),
            // Available via Settings but hidden by default.
            ModuleSetting(id: "screenTime",   isEnabled: false),
            ModuleSetting(id: "pomodoro",     isEnabled: false),
            ModuleSetting(id: "reminders",    isEnabled: false),
            ModuleSetting(id: "calendar",     isEnabled: false),
            ModuleSetting(id: "clipboard",    isEnabled: false),
            ModuleSetting(id: "system",       isEnabled: false),
            ModuleSetting(id: "launcher",     isEnabled: false),
            ModuleSetting(id: "customize",    isEnabled: false),
        ],
        launchAtLogin: false,
        defaultExpansionMode: .dashboard
    )

    public static func mergingPersisted(_ persisted: AppSettings,
                                        into defaults: AppSettings = .defaults) -> AppSettings {
        let defaultModulesByID = Dictionary(uniqueKeysWithValues: defaults.modules.map { ($0.id, $0) })
        var seen = Set<String>()

        var modules = persisted.modules.compactMap { module -> ModuleSetting? in
            guard defaultModulesByID[module.id] != nil else { return nil }
            guard seen.insert(module.id).inserted else { return nil }
            return module
        }

        modules.append(contentsOf: defaults.modules.filter { seen.insert($0.id).inserted })

        return AppSettings(modules: modules,
                           launchAtLogin: persisted.launchAtLogin,
                           defaultExpansionMode: persisted.defaultExpansionMode,
                           appearance: persisted.appearance,
                           activeWorkspaceProfileID: persisted.activeWorkspaceProfileID,
                           onboarding: persisted.onboarding,
                           isAquariumBatterySaverEnabled: persisted.isAquariumBatterySaverEnabled)
    }
}
