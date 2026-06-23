import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?
    private var notchWindow: NotchWindow?
    private var settingsWindowController: SettingsWindowController?
    private let registry = ModuleRegistry()
    private let settings = SettingsStore(url: SettingsStore.defaultURL())

    private let moduleTitles = [
        "quickToggles": "Quick Toggles",
        "actions": "Actions",
        "launcher": "Launcher",
        "media": "Now Playing",
        "calendar": "Calendar",
        "system": "Battery & System",
        "shelf": "Drop Shelf",
        "code": "Code",
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.load()
        registerModules()

        let notchWindow = NotchWindow(registry: registry, settings: settings)
        notchWindow.show()
        self.notchWindow = notchWindow

        let settingsWindowController = SettingsWindowController(
            settings: settings,
            titles: moduleTitles
        ) { [weak self] updated in
            guard let self else { return }
            self.settings.replace(updated)
            self.settings.save()
            self.notchWindow?.reload()
        }
        self.settingsWindowController = settingsWindowController

        let menuBar = MenuBarController()
        menuBar.onToggleNotch = { [weak notchWindow] in
            notchWindow?.toggle()
        }
        menuBar.onOpenSettings = { [weak settingsWindowController] in
            settingsWindowController?.show()
        }
        self.menuBar = menuBar
    }

    func applicationWillTerminate(_ notification: Notification) {
        notchWindow?.tearDown()
    }

    private func registerModules() {
        registry.register(QuickTogglesModule())
        registry.register(ActionsModule())
        registry.register(LauncherModule())
        registry.register(MediaModule())
        registry.register(CalendarModule())
        registry.register(SystemModule())
        registry.register(ShelfModule())
        registry.register(CodeModule())
    }
}
