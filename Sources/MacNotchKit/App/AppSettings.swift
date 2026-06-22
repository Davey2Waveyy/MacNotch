import Foundation

public struct ModuleSetting: Codable, Equatable, Sendable {
    public var id: String
    public var isEnabled: Bool
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var modules: [ModuleSetting]
    public var launchAtLogin: Bool

    public static let defaults = AppSettings(
        modules: [
            ModuleSetting(id: "media", isEnabled: true),
            ModuleSetting(id: "calendar", isEnabled: true),
            ModuleSetting(id: "system", isEnabled: true),
            ModuleSetting(id: "shelf", isEnabled: true),
        ],
        launchAtLogin: false
    )
}
