import Foundation

public struct AppDataMigrator {
    private let locations: AppDataLocations
    private let fileManager: FileManager

    public init(locations: AppDataLocations = AppDataLocations(),
                fileManager: FileManager = .default) {
        self.locations = locations
        self.fileManager = fileManager
    }

    @discardableResult
    public func migrateIfNeeded() -> Bool {
        if fileManager.fileExists(atPath: locations.migrationMarkerURL.path) {
            return true
        }
        guard fileManager.fileExists(atPath: locations.legacyDirectory.path) else {
            return writeMarker()
        }

        do {
            try fileManager.createDirectory(at: locations.currentDirectory, withIntermediateDirectories: true)
            let legacyContents = try fileManager.contentsOfDirectory(
                at: locations.legacyDirectory,
                includingPropertiesForKeys: nil
            )
            for source in legacyContents {
                let destination = locations.currentDirectory.appendingPathComponent(source.lastPathComponent)
                if !fileManager.fileExists(atPath: destination.path) {
                    try fileManager.copyItem(at: source, to: destination)
                }
            }
            return writeMarker()
        } catch {
            NSLog("NotchApple migration failed: \(error.localizedDescription)")
            return false
        }
    }

    private func writeMarker() -> Bool {
        do {
            try fileManager.createDirectory(at: locations.currentDirectory, withIntermediateDirectories: true)
            try Data("migrated".utf8).write(to: locations.migrationMarkerURL, options: .atomic)
            return true
        } catch {
            NSLog("NotchApple migration marker failed: \(error.localizedDescription)")
            return false
        }
    }
}
