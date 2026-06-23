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

    public init(modules: [ModuleSetting],
                launchAtLogin: Bool,
                defaultExpansionMode: ExpansionMode = .dashboard) {
        self.modules = modules
        self.launchAtLogin = launchAtLogin
        self.defaultExpansionMode = defaultExpansionMode
    }

    private enum CodingKeys: String, CodingKey {
        case modules, launchAtLogin, defaultExpansionMode
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
    }

    public static let defaults = AppSettings(
        modules: [
            // Page 1
            ModuleSetting(id: "shelf",        isEnabled: true),
            ModuleSetting(id: "media",        isEnabled: true),
            ModuleSetting(id: "quickToggles", isEnabled: true),
            ModuleSetting(id: "reminders",    isEnabled: true),
            // Page 2
            ModuleSetting(id: "timers",       isEnabled: true),
            ModuleSetting(id: "clipboard",    isEnabled: true),
            ModuleSetting(id: "screenTime",   isEnabled: true),
            ModuleSetting(id: "calendar",     isEnabled: true),
            // Page 3
            ModuleSetting(id: "system",       isEnabled: true),
            ModuleSetting(id: "actions",      isEnabled: true),
            ModuleSetting(id: "launcher",     isEnabled: true),
            ModuleSetting(id: "code",         isEnabled: true),
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
                           defaultExpansionMode: persisted.defaultExpansionMode)
    }
}
