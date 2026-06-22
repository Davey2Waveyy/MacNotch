import Foundation

public final class SettingsStore {
    public private(set) var settings: AppSettings
    private let url: URL

    public init(url: URL) {
        self.url = url
        self.settings = .defaults
    }

    public func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return }
        settings = AppSettings.mergingPersisted(decoded)
    }

    public func save() {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: url, options: .atomic)
        }
    }

    public func setEnabled(_ id: String, _ on: Bool) {
        guard let i = settings.modules.firstIndex(where: { $0.id == id }) else { return }
        settings.modules[i].isEnabled = on
    }

    public func move(id: String, to index: Int) {
        guard let from = settings.modules.firstIndex(where: { $0.id == id }) else { return }
        let item = settings.modules.remove(at: from)
        let clamped = max(0, min(index, settings.modules.count))
        settings.modules.insert(item, at: clamped)
    }

    public func orderedEnabledIDs() -> [String] {
        settings.modules.filter { $0.isEnabled }.map { $0.id }
    }

    /// Default store location in Application Support.
    public static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        return base.appendingPathComponent("MacNotch/settings.json")
    }
}
