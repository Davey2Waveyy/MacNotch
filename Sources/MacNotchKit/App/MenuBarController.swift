import AppKit

@MainActor
final class MenuBarController {
    private let item: NSStatusItem
    var onOpenSettings: (() -> Void)?
    var onToggleNotch: (() -> Void)?

    init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "rectangle.topthird.inset.filled",
            accessibilityDescription: "MacNotch"
        )

        let menu = NSMenu()
        menu.addItem(withTitle: "Open Settings…", action: #selector(openSettings), keyEquivalent: ",")
            .target = self
        menu.addItem(withTitle: "Toggle Notch", action: #selector(toggleNotch), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit MacNotch", action: #selector(quit), keyEquivalent: "q")
            .target = self
        item.menu = menu
    }

    @objc private func openSettings() { onOpenSettings?() }
    @objc private func toggleNotch() { onToggleNotch?() }
    @objc private func quit() { NSApp.terminate(nil) }
}
