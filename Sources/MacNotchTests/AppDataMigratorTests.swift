import Foundation
import MacNotchKit

func appDataMigratorTests() {
    func root() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    test("AppDataLocations derives legacy and current support directories") {
        let base = root()
        let locations = AppDataLocations(baseApplicationSupportURL: base)
        expectEqual(locations.currentDirectory.lastPathComponent, "NotchApple", "current directory")
        expectEqual(locations.legacyDirectory.lastPathComponent, "MacNotch", "legacy directory")
        expectEqual(locations.settingsURL.lastPathComponent, "settings.json", "settings path")
    }

    test("migration copies legacy data once and writes marker") {
        let base = root()
        let locations = AppDataLocations(baseApplicationSupportURL: base)
        try! FileManager.default.createDirectory(at: locations.legacyDirectory, withIntermediateDirectories: true)
        try! Data("legacy".utf8).write(to: locations.legacyDirectory.appendingPathComponent("settings.json"))

        let migrator = AppDataMigrator(locations: locations)
        expect(migrator.migrateIfNeeded(), "first migration succeeds")
        expectEqual(
            try! String(contentsOf: locations.currentDirectory.appendingPathComponent("settings.json")),
            "legacy",
            "legacy settings copied"
        )
        expect(FileManager.default.fileExists(atPath: locations.migrationMarkerURL.path), "marker written")

        try! Data("new".utf8).write(to: locations.currentDirectory.appendingPathComponent("settings.json"))
        expect(migrator.migrateIfNeeded(), "second migration is a no-op success")
        expectEqual(
            try! String(contentsOf: locations.currentDirectory.appendingPathComponent("settings.json")),
            "new",
            "current settings not overwritten"
        )
    }
}
