import AppKit
import SwiftUI

@MainActor
final class ActionsModule: NotchModule {
    let id = "actions"
    let title = "Actions"
    var isEnabled = true

    func collapsedView() -> AnyView? { nil }

    func expandedView() -> AnyView? { nil }

    func dashboardTile() -> AnyView? {
        AnyView(ActionsDashboardTile(onAction: { [weak self] action in self?.perform(action) }))
    }

    func wideBarView() -> AnyView? { nil }

    func activate() {}
    func deactivate() {}
    func refresh() async {}

    private func perform(_ action: QuickAction) {
        switch action {
        case .openTerminal:
            openApp(bundleID: "com.apple.Terminal")
        case .openFinder:
            NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser)
        case .openSettings:
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:")!)
        case .lockScreen:
            runShell("/usr/bin/pmset", args: ["displaysleepnow"])
        case .screenshotArea:
            runShell("/usr/sbin/screencapture", args: ["-iU"])
        case .newNote:
            runOsascript("""
            tell application "Notes"
                activate
                tell account "iCloud"
                    make new note
                end tell
            end tell
            """)
        }
    }

    private func openApp(bundleID: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
    }

    private func runShell(_ path: String, args: [String]) {
        let task = Process()
        task.launchPath = path
        task.arguments = args
        try? task.run()
    }

    private func runOsascript(_ source: String) {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", source]
        try? task.run()
    }
}

enum QuickAction: String, CaseIterable, Identifiable {
    case openTerminal
    case openFinder
    case openSettings
    case lockScreen
    case screenshotArea
    case newNote

    var id: String { rawValue }

    var label: String {
        switch self {
        case .openTerminal: return "Terminal"
        case .openFinder: return "Finder"
        case .openSettings: return "Settings"
        case .lockScreen: return "Sleep"
        case .screenshotArea: return "Snip"
        case .newNote: return "Note"
        }
    }

    var systemImage: String {
        switch self {
        case .openTerminal: return "terminal"
        case .openFinder: return "folder"
        case .openSettings: return "gear"
        case .lockScreen: return "moon.zzz"
        case .screenshotArea: return "scissors"
        case .newNote: return "square.and.pencil"
        }
    }

    var accent: Color {
        switch self {
        case .openTerminal: return Color(red: 0.27, green: 0.85, blue: 0.62)
        case .openFinder:   return Color(red: 0.39, green: 0.66, blue: 1.0)
        case .openSettings: return Color(red: 0.75, green: 0.75, blue: 0.82)
        case .lockScreen:   return Color(red: 0.62, green: 0.55, blue: 1.0)
        case .screenshotArea: return Color(red: 1.0, green: 0.62, blue: 0.42)
        case .newNote:      return Color(red: 1.0, green: 0.82, blue: 0.36)
        }
    }
}
