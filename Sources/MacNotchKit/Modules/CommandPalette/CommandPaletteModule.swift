import SwiftUI

@MainActor
final class CommandPaletteModule: NotchModule {
    let id = "commandPalette"
    let title = "Command Palette"
    var isEnabled = true

    private let model: CommandPaletteModel

    init(commands: [CommandPaletteCommand] = []) {
        self.model = CommandPaletteModel(commands: commands)
    }

    func collapsedView() -> AnyView? { nil }
    func expandedView() -> AnyView? { nil }

    func dashboardTile() -> AnyView? {
        AnyView(CommandPaletteTile(model: model))
    }

    func wideBarView() -> AnyView? {
        AnyView(WideBarItem(systemImage: "command", text: "Command Palette"))
    }

    func activate() {}
    func deactivate() {}
    func refresh() async {}
}
