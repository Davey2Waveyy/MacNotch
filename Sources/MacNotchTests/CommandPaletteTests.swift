import MacNotchKit

func commandPaletteTests() {
    test("command palette filters by title and keyword") {
        let commands = [
            CommandPaletteCommand(id: "settings", title: "Open Settings", keywords: ["preferences"], action: {}),
            CommandPaletteCommand(id: "coding", title: "Use Coding Workspace", keywords: ["code", "profile"], action: {})
        ]
        let model = CommandPaletteModel(commands: commands)
        expectEqual(model.filteredCommands(query: "pref").map(\.id), ["settings"], "keyword filter")
        expectEqual(model.filteredCommands(query: "coding").map(\.id), ["coding"], "title filter")
    }

    test("empty query returns all commands") {
        let model = CommandPaletteModel(commands: [
            CommandPaletteCommand(id: "a", title: "A", keywords: [], action: {}),
            CommandPaletteCommand(id: "b", title: "B", keywords: [], action: {})
        ])
        expectEqual(model.filteredCommands(query: "").map(\.id), ["a", "b"], "all commands")
    }
}
