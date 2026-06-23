import Foundation

struct PinnedApp: Codable, Equatable, Identifiable {
    var bundleID: String
    var path: String
    var name: String

    var id: String { bundleID }
}

final class LauncherStore {
    private let url: URL
    private(set) var apps: [PinnedApp] = []

    init(url: URL) {
        self.url = url
        load()
    }

    static func defaultURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = support.appendingPathComponent("MacNotch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("launcher.json")
    }

    func add(path: String, name: String, bundleID: String) {
        guard !apps.contains(where: { $0.bundleID == bundleID }) else { return }
        apps.append(PinnedApp(bundleID: bundleID, path: path, name: name))
        save()
    }

    func remove(_ bundleID: String) {
        apps.removeAll { $0.bundleID == bundleID }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([PinnedApp].self, from: data) else { return }
        apps = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(apps) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
