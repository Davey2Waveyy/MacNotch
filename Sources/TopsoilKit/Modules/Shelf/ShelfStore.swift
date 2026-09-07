import Foundation

/// Persisted holding tray for dropped files. Holds *references* (bookmarks), never
/// copies — dropping a file parks a pointer to it; the original is untouched.
public final class ShelfStore {
    public struct Resolution: Equatable, Sendable {
        public let url: URL
        public let bookmarkDataIsStale: Bool

        public init(url: URL, bookmarkDataIsStale: Bool) {
            self.url = url
            self.bookmarkDataIsStale = bookmarkDataIsStale
        }
    }

    public private(set) var items: [ShelfItem] = []
    private let url: URL
    private static let bookmarkCreationOptions: URL.BookmarkCreationOptions = [
        .withSecurityScope,
        .securityScopeAllowOnlyReadAccess
    ]
    private static let bookmarkResolutionOptions: URL.BookmarkResolutionOptions = [
        .withSecurityScope,
        .withoutUI
    ]

    public init(url: URL) {
        self.url = url
        load()
    }

    public func add(_ fileURL: URL) {
        guard let data = try? fileURL.bookmarkData(
            options: Self.bookmarkCreationOptions,
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
        resolveWithStatus(item)?.url
    }

    public func resolveWithStatus(_ item: ShelfItem) -> Resolution? {
        var isStale = false
        guard let resolvedURL = try? URL(
            resolvingBookmarkData: item.bookmark,
            options: Self.bookmarkResolutionOptions,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }

        return Resolution(url: resolvedURL, bookmarkDataIsStale: isStale)
    }

    public func withResolvedURL<T>(
        for item: ShelfItem,
        accessSecurityScopedResource: Bool = false,
        _ body: (Resolution) throws -> T
    ) rethrows -> T? {
        guard let resolution = resolveWithStatus(item) else { return nil }

        let didStartAccessing = accessSecurityScopedResource
            ? resolution.url.startAccessingSecurityScopedResource()
            : false
        defer {
            if didStartAccessing {
                resolution.url.stopAccessingSecurityScopedResource()
            }
        }

        return try body(resolution)
    }

    /// True when the bookmarked file can no longer be found (moved or deleted).
    public func isStale(_ item: ShelfItem) -> Bool {
        let resolution = resolveWithStatus(item)
        let fileExists = resolution.map { FileManager.default.fileExists(atPath: $0.url.path) } ?? false
        return Self.isStale(resolution: resolution, fileExists: fileExists)
    }

    public static func isStale(resolution: Resolution?, fileExists: Bool) -> Bool {
        guard let resolution else { return true }
        return resolution.bookmarkDataIsStale || !fileExists
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
        let dir = AppDataLocations().currentDirectory
        return dir.appendingPathComponent("shelf.json")
    }
}
