import Foundation
import MacNotchKit

func shelfStoreTests() {
    func tempStoreURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    }
    func tempFile(_ name: String) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "-" + name)
        try? "hi".write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    test("shelf: add persists and resolves back to the file") {
        let storeURL = tempStoreURL()
        let file = tempFile("report.pdf")

        let a = ShelfStore(url: storeURL)
        a.add(file)
        expect(a.items.count == 1, "one item after add")
        expect(a.items.first?.name == file.lastPathComponent, "name captured")

        let b = ShelfStore(url: storeURL) // reload from disk
        expect(b.items.count == 1, "item survives reload")
        expect(b.resolve(b.items[0])?.lastPathComponent == file.lastPathComponent, "resolves to original")
    }

    test("shelf: remove drops the right item") {
        let store = ShelfStore(url: tempStoreURL())
        let a = tempFile("a.txt")
        let b = tempFile("b.txt")
        store.add(a)
        store.add(b)
        store.remove(at: 0)
        expect(store.items.count == 1, "one item left")
        expect(store.items[0].name == b.lastPathComponent, "the remaining item is b")
    }

    test("shelf: clear empties the tray") {
        let store = ShelfStore(url: tempStoreURL())
        store.add(tempFile("x.txt"))
        store.clear()
        expect(store.items.isEmpty, "cleared")
    }

    test("shelf: a deleted file is reported stale") {
        let store = ShelfStore(url: tempStoreURL())
        let file = tempFile("gone.txt")
        store.add(file)
        try? FileManager.default.removeItem(at: file)
        expect(store.isStale(store.items[0]), "missing file is stale")
    }

    test("shelf: out-of-range remove is a safe no-op") {
        let store = ShelfStore(url: tempStoreURL())
        store.add(tempFile("only.txt"))
        store.remove(at: 9)
        expect(store.items.count == 1, "no crash, nothing removed")
    }
}
