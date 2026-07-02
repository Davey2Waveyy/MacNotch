import AppKit

/// Persisted clipboard history (text only, most-recent first, capped at maxCount).
@MainActor
public final class ClipboardStore {
    public private(set) var entries: [ClipboardEntry] = []
    public let maxCount: Int

    private let url: URL

    public init(url: URL, maxCount: Int = 20) {
        self.url = url
        self.maxCount = maxCount
        load()
    }

    /// Returns true when a new unique entry was added.
    @discardableResult
    public func add(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, entries.first?.text != trimmed else { return false }

        entries.insert(ClipboardEntry(text: trimmed), at: 0)
        if entries.count > maxCount { entries = Array(entries.prefix(maxCount)) }
        save()
        return true
    }

    public func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    public func clear() {
        entries.removeAll()
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ClipboardEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }

    public static func defaultURL() -> URL {
        let dir = AppDataLocations().currentDirectory
        return dir.appendingPathComponent("clipboard.json")
    }
}
