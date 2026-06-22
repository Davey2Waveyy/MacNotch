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

    public init(modules: [ModuleSetting], launchAtLogin: Bool) {
        self.modules = modules
        self.launchAtLogin = launchAtLogin
    }

    public static let defaults = AppSettings(
        modules: [
            ModuleSetting(id: "media", isEnabled: true),
            ModuleSetting(id: "calendar", isEnabled: true),
            ModuleSetting(id: "system", isEnabled: true),
            ModuleSetting(id: "shelf", isEnabled: true),
        ],
        launchAtLogin: false
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

        return AppSettings(modules: modules, launchAtLogin: persisted.launchAtLogin)
    }
}
