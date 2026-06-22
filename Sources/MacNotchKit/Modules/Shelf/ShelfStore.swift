import Foundation

/// Persisted holding tray for dropped files. Holds *references* (bookmarks), never
/// copies — dropping a file parks a pointer to it; the original is untouched.
public final class ShelfStore {
    public private(set) var items: [ShelfItem] = []
    private let url: URL

    public init(url: URL) {
        self.url = url
        load()
    }

    public func add(_ fileURL: URL) {
        guard let data = try? fileURL.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        items.append(ShelfItem(name: fileURL.lastPathComponent, bookmark: data))
        save()
    }

    public func remove(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
        save()
    }

    public func clear() {
        items.removeAll()
        save()
    }

    /// Resolves a bookmark back to its current file URL, or nil if unresolvable.
    public func resolve(_ item: ShelfItem) -> URL? {
        var isStale = false
        return try? URL(
            resolvingBookmarkData: item.bookmark,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }

    /// True when the bookmarked file can no longer be found (moved or deleted).
    public func isStale(_ item: ShelfItem) -> Bool {
        guard let resolved = resolve(item) else { return true }
        return !FileManager.default.fileExists(atPath: resolved.path)
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ShelfItem].self, from: data)
        else { return }
        items = decoded
    }

    private func save() {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: url, options: .atomic)
        }
    }

    public static func defaultURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MacNotch/shelf.json")
    }
}
