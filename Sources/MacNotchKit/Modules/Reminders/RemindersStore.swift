import Foundation

@MainActor
public final class RemindersStore {
    public private(set) var reminders: [Reminder] = []
    private let url: URL

    public init(url: URL) {
        self.url = url
        load()
    }

    public func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        reminders.insert(Reminder(title: trimmed), at: 0)
        save()
    }

    public func toggle(id: UUID) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[index].isDone.toggle()
        save()
    }

    public func remove(id: UUID) {
        reminders.removeAll { $0.id == id }
        save()
    }

    public func clearDone() {
        reminders.removeAll { $0.isDone }
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Reminder].self, from: data) else { return }
        reminders = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        try? data.write(to: url, options: .atomic)
    }

    public static func defaultURL() -> URL {
        let dir = AppDataLocations().currentDirectory
        return dir.appendingPathComponent("reminders.json")
    }
}
