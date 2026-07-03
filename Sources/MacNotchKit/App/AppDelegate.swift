import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?
    private var notchWindow: NotchWindow?
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: OnboardingWindowController?
    private let registry = ModuleRegistry()
    private let settings = SettingsStore(url: SettingsStore.defaultURL())
    private var customizeModule: CustomizeModule?

    private let moduleTitles: [String: String] = [
        "screenTime":   "Screen Time",
        "quickToggles": "Quick Toggles",
        "timers":       "Timers",
        "pomodoro":     "Pomodoro",
        "actions":      "Actions",
        "launcher":     "Launcher",
        "media":        "Now Playing",
        "calendar":     "Calendar",
        "system":       "Battery & System",
        "shelf":        "Drop Shelf",
        "code":         "Code",
        "commandPalette": "Command Palette",
        "stocks":       "Stocks",
        "clipboard":    "Clipboard",
        "reminders":    "Reminders",
        "customize":    "Customize",
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = AppDataMigrator().migrateIfNeeded()
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
            self.applySettings(updated)
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

        let onboarding = OnboardingWindowController()
        onboarding.showIfNeeded(settings: settings.settings) { [weak self] state in
            guard let self else { return }
            var current = self.settings.settings
            current.onboarding = state
            self.applySettings(current)
            self.onboardingWindowController = nil
        }
        self.onboardingWindowController = onboarding
    }

    func applicationWillTerminate(_ notification: Notification) {
        notchWindow?.tearDown()
    }

    private func applySettings(_ updated: AppSettings) {
        settings.replace(updated)
        settings.save()
        customizeModule?.sync(updated)
        settingsWindowController?.sync(updated)
        notchWindow?.reload()
    }

    private func registerModules() {
        // Page 1: Now Playing, Quick Toggles, Timers, Actions, Drop Shelf.
        // Page 2: Code CLI tools (full-width solo tile).
        // Page 3+: Stocks, System, Launcher, etc. based on settings order.
        registry.register(QuickTogglesModule())
        registry.register(ScreenTimeModule())
        registry.register(TimersModule())
        registry.register(PomodoroModule())
        registry.register(ShelfModule())
        registry.register(ActionsModule())
        registry.register(MediaModule())
        registry.register(RemindersModule())
        registry.register(CalendarModule())
        registry.register(ClipboardModule())
        registry.register(SystemModule())
        registry.register(LauncherModule())
        registry.register(CodeModule())
        registry.register(CommandPaletteModule(commands: defaultCommands()))
        registry.register(StocksModule())

        let customize = CustomizeModule(
            settings: settings.settings,
            titles: moduleTitles
        ) { [weak self] updated in
            self?.applySettings(updated)
        }
        customizeModule = customize
        registry.register(customize)
    }

    private func defaultCommands() -> [CommandPaletteCommand] {
        var commands = [
            CommandPaletteCommand(id: "open-settings", title: "Open Settings", keywords: ["preferences"]) { [weak self] in
                self?.settingsWindowController?.show()
            },
            CommandPaletteCommand(id: "toggle-notch", title: "Toggle Notch", keywords: ["panel", "dashboard"]) { [weak self] in
                self?.notchWindow?.toggle()
            }
        ]
        for profile in WorkspaceProfile.defaults {
            commands.append(CommandPaletteCommand(
                id: "workspace-\(profile.id)",
                title: "Use \(profile.name) Workspace",
                keywords: ["workspace", "profile", profile.id]
            ) { [weak self] in
                guard let self else { return }
                var current = self.settings.settings
                profile.apply(to: &current)
                self.applySettings(current)
            })
        }
        return commands
    }
}
