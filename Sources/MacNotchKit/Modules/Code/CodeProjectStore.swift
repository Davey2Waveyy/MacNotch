import Foundation

/// Persisted list of pinned project folders (bookmarks), mirroring `ShelfStore`.
public final class CodeProjectStore {
    public private(set) var projects: [CodeProject] = []
    private let url: URL

    public init(url: URL) {
        self.url = url
        load()
    }

    /// Pins a folder. Ignores duplicates (same resolved path already pinned).
    public func add(_ folderURL: URL) {
        guard let data = try? folderURL.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }

        let candidatePath = folderURL.standardizedFileURL.path
        let alreadyPinned = projects.contains { resolve($0)?.standardizedFileURL.path == candidatePath }
        guard !alreadyPinned else { return }

        projects.append(CodeProject(name: folderURL.lastPathComponent, bookmark: data))
        save()
    }

    public func remove(at index: Int) {
        guard projects.indices.contains(index) else { return }
        projects.remove(at: index)
        save()
    }

    public func resolve(_ project: CodeProject) -> URL? {
        var isStale = false
        return try? URL(
            resolvingBookmarkData: project.bookmark,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([CodeProject].self, from: data)
        else { return }
        projects = decoded
    }

    private func save() {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if let data = try? JSONEncoder().encode(projects) {
            try? data.write(to: url, options: .atomic)
        }
    }

    public static func defaultURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MacNotch/code-projects.json")
    }
}
