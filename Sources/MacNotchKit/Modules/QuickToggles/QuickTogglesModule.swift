import AppKit
import SwiftUI

@MainActor
final class QuickTogglesModule: NotchModule {
    let id = "quickToggles"
    let title = "Quick Toggles"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var darkMode = false
        @Published var muted = false
        @Published var caffeinated = false
        @Published var dndActive = false
    }

    private let state = StateBox()
    private var caffeinateTask: Process?
    private var poll: Timer?

    init() {
        refreshState()
    }

    func collapsedView() -> AnyView? { nil }

    func expandedView() -> AnyView {
        AnyView(QuickTogglesView(state: state, controller: self))
    }

    func dashboardTile() -> AnyView? {
        AnyView(QuickTogglesDashboardTile(state: state, controller: self))
    }

    func wideBarView() -> AnyView? { nil }

    func activate() {
        refreshState()
        poll = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshState() }
        }
    }

    func deactivate() {
        poll?.invalidate()
        poll = nil
    }

    func refresh() async {
        refreshState()
    }

    // MARK: - Actions

    func toggleDarkMode() {
        state.darkMode.toggle()
        let target = state.darkMode
        runOsascript("""
        tell application "System Events"
            tell appearance preferences
                set dark mode to \(target)
            end tell
        end tell
        """)
    }

    func toggleMute() {
        state.muted.toggle()
        let target = state.muted ? "true" : "false"
        runOsascript("set volume output muted \(target)")
    }

    func toggleCaffeinate() {
        if let task = caffeinateTask, task.isRunning {
            task.terminate()
            caffeinateTask = nil
            state.caffeinated = false
        } else {
            let task = Process()
            task.launchPath = "/usr/bin/caffeinate"
            task.arguments = ["-d"]
            do {
                try task.run()
                caffeinateTask = task
                state.caffeinated = true
            } catch {
                state.caffeinated = false
            }
        }
    }

    func openDoNotDisturbShortcut() {
        // macOS no longer exposes DND via AppleScript reliably; open Control Center.
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }

    private func refreshState() {
        // Dark mode
        let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        state.darkMode = (style == "Dark")
        // Mute
        let muteScript = "output muted of (get volume settings)"
        if let result = readOsascript(muteScript) {
            state.muted = result.contains("true")
        }
    }

    @discardableResult
    private func runOsascript(_ source: String) -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", source]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    private func readOsascript(_ source: String) -> String? {
        runOsascript(source)
    }
}
