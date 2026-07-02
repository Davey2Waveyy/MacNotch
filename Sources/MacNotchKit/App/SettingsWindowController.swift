import AppKit
import SwiftUI

/// Holds the settings window's live read model so the view always renders the
/// latest persisted `AppSettings`, mirroring `CustomizeModule.SettingsProxy`.
@MainActor
public final class SettingsWindowModel: ObservableObject {
    @Published public var settings: AppSettings

    public init(_ settings: AppSettings) {
        self.settings = settings
    }

    /// Republishes an externally persisted settings value so the window stays in sync.
    public func sync(_ newSettings: AppSettings) {
        settings = newSettings
    }
}

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let settings: SettingsStore
    private let titles: [String: String]
    private let onChange: (AppSettings) -> Void
    private let model: SettingsWindowModel

    init(settings: SettingsStore, titles: [String: String], onChange: @escaping (AppSettings) -> Void) {
        self.settings = settings
        self.titles = titles
        self.onChange = onChange
        var initial = settings.settings
        initial.launchAtLogin = LoginItem.isEnabled()
        self.model = SettingsWindowModel(initial)
    }

    /// Called by AppDelegate after persisting a settings change so the window stays in sync.
    func sync(_ newSettings: AppSettings) {
        model.sync(newSettings)
    }

    func show() {
        if window == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = NotchBrand.settingsTitle
            window.isReleasedWhenClosed = false
            window.center()

            let view = SettingsView(model: model, titles: titles, onChange: onChange)
            window.contentView = NSHostingView(rootView: view)
            self.window = window
        }

        model.settings.launchAtLogin = LoginItem.isEnabled()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
