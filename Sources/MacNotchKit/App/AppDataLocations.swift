import Foundation

public struct AppDataLocations: Sendable {
    public let baseApplicationSupportURL: URL

    public init(baseApplicationSupportURL: URL = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
    )[0]) {
        self.baseApplicationSupportURL = baseApplicationSupportURL
    }

    public var currentDirectory: URL {
        baseApplicationSupportURL.appendingPathComponent(NotchBrand.applicationSupportDirectoryName, isDirectory: true)
    }

    public var legacyDirectory: URL {
        baseApplicationSupportURL.appendingPathComponent(NotchBrand.legacyApplicationSupportDirectoryName, isDirectory: true)
    }

    public var migrationMarkerURL: URL {
        currentDirectory.appendingPathComponent(".macnotch-migrated")
    }

    public var settingsURL: URL {
        currentDirectory.appendingPathComponent("settings.json")
    }
}
