import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let settings: SettingsStore
    private let titles: [String: String]
    private let onChange: (AppSettings) -> Void

    init(settings: SettingsStore, titles: [String: String], onChange: @escaping (AppSettings) -> Void) {
        self.settings = settings
        self.titles = titles
        self.onChange = onChange
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 320),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = NotchBrand.settingsTitle
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }

        var initial = settings.settings
        initial.launchAtLogin = LoginItem.isEnabled()

        let view = SettingsView(settings: initial, titles: titles, onChange: onChange)
        window?.contentView = NSHostingView(rootView: view)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
