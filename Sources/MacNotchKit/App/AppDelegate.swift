import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?
    private var notchWindow: NotchWindow?
    private let registry = ModuleRegistry()
    private let settings = SettingsStore(url: SettingsStore.defaultURL())

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.load()
        registerModules()

        let notchWindow = NotchWindow(registry: registry, settings: settings)
        notchWindow.show()
        self.notchWindow = notchWindow

        let menuBar = MenuBarController()
        menuBar.onToggleNotch = { [weak notchWindow] in
            notchWindow?.toggle()
        }
        menuBar.onOpenSettings = {}
        self.menuBar = menuBar
    }

    func applicationWillTerminate(_ notification: Notification) {
        notchWindow?.tearDown()
    }

    private func registerModules() {
        registry.register(MediaModule())
        registry.register(CalendarModule())
        registry.register(SystemModule())
    }
}
