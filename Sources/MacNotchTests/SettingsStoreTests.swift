import Foundation
import MacNotchKit

func settingsStoreTests() {
    func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
    }

    test("round-trips settings to disk") {
        let url = tempURL()
        let a = SettingsStore(url: url)
        a.setEnabled("media", false)
        a.save()

        let b = SettingsStore(url: url)
        b.load()
        let media = b.settings.modules.first { $0.id == "media" }
        expect(media?.isEnabled == false, "media disabled after reload")
    }

    test("reorder moves module to the end") {
        let store = SettingsStore(url: tempURL())
        let first = store.settings.modules.first!.id
        store.move(id: first, to: store.settings.modules.count - 1)
        expectEqual(store.settings.modules.last!.id, first, "moved id is last")
    }

    test("orderedEnabledIDs skips disabled") {
        let store = SettingsStore(url: tempURL())
        store.setEnabled("system", false)
        expect(!store.orderedEnabledIDs().contains("system"), "system excluded")
        expect(store.orderedEnabledIDs().contains("media"), "media included")
    }

    test("load merges persisted known modules with defaults and drops unknown ids") {
        let url = tempURL()
        let persisted = AppSettings(
            modules: [
                ModuleSetting(id: "system", isEnabled: false),
                ModuleSetting(id: "legacy", isEnabled: true),
                ModuleSetting(id: "media", isEnabled: true),
            ],
            launchAtLogin: true
        )
        let data = try! JSONEncoder().encode(persisted)
        try! data.write(to: url, options: .atomic)

        let store = SettingsStore(url: url)
        store.load()

        expectEqual(
            store.settings.modules.map(\.id),
            ["system", "media", "calendar", "shelf"],
            "known persisted order preserved and missing defaults appended"
        )
        expectEqual(
            store.settings.modules.map(\.isEnabled),
            [false, true, true, true],
            "persisted enablement preserved and appended defaults keep default enablement"
        )
        expectEqual(store.settings.launchAtLogin, true, "other persisted settings survive merge")
    }
}
