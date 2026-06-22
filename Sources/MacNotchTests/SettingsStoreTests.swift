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
}
