import Combine
import Foundation

public struct CommandPaletteCommand {
    public let id: String
    public let title: String
    public let keywords: [String]
    public let action: () -> Void

    public init(id: String, title: String, keywords: [String], action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.keywords = keywords
        self.action = action
    }
}

public final class CommandPaletteModel: ObservableObject {
    public let commands: [CommandPaletteCommand]

    public init(commands: [CommandPaletteCommand]) {
        self.commands = commands
    }

    public func filteredCommands(query: String) -> [CommandPaletteCommand] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return commands }
        return commands.filter { command in
            command.title.lowercased().contains(normalized)
                || command.keywords.contains { $0.lowercased().contains(normalized) }
        }
    }
}
