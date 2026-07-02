import Foundation
import MacNotchKit

func appDataPersistenceTests() {
    func nestedStoreURL(_ fileName: String) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("nested", isDirectory: true)
            .appendingPathComponent(fileName)
    }

    test("clipboard store creates parent directory before saving") {
        let url = nestedStoreURL("clipboard.json")

        MainActor.assumeIsolated {
            let store = ClipboardStore(url: url)
            expect(store.add("hello notch"), "entry added")
        }

        let data = try? Data(contentsOf: url)
        let entries = data.flatMap { try? JSONDecoder().decode([ClipboardEntry].self, from: $0) }
        expectEqual(entries?.map(\.text), ["hello notch"], "clipboard persisted on a fresh filesystem")
    }

    test("reminders store creates parent directory before saving") {
        let url = nestedStoreURL("reminders.json")

        MainActor.assumeIsolated {
            let store = RemindersStore(url: url)
            store.add("Ship review fix")
        }

        let data = try? Data(contentsOf: url)
        let reminders = data.flatMap { try? JSONDecoder().decode([Reminder].self, from: $0) }
        expectEqual(reminders?.map(\.title), ["Ship review fix"], "reminders persisted on a fresh filesystem")
    }
}
