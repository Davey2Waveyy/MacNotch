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
            accessibilityDescription: NotchBrand.productName
        )

        let menu = NSMenu()
        menu.addItem(withTitle: "Open \(NotchBrand.productName)", action: #selector(toggleNotch), keyEquivalent: "")
            .target = self
        menu.addItem(withTitle: "Open Settings…", action: #selector(openSettings), keyEquivalent: ",")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: NotchBrand.quitMenuTitle, action: #selector(quit), keyEquivalent: "q")
            .target = self
        item.menu = menu
    }

    @objc private func openSettings() { onOpenSettings?() }
    @objc private func toggleNotch() { onToggleNotch?() }
    @objc private func quit() { NSApp.terminate(nil) }
}
