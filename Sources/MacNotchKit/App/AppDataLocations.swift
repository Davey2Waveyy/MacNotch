import Foundation

public struct AppDataLocations: Sendable {
    public let baseApplicationSupportURL: URL

    public init(baseApplicationSupportURL: URL = Self.defaultBase()) {
        self.baseApplicationSupportURL = baseApplicationSupportURL
    }

    /// `TOPSOIL_DATA_DIR` points the whole data tree somewhere else — used by
    /// the capture/debug harness to run against staged settings without ever
    /// touching the real Application Support directory.
    public static func defaultBase() -> URL {
        if let override = ProcessInfo.processInfo.environment["TOPSOIL_DATA_DIR"],
           !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
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
