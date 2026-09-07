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

    // Observers — no polling timers at all.
    private var themeObserver: NSObjectProtocol?
    private var audioObserver: NSObjectProtocol?

    init() {
        snapshotState()
    }

    func collapsedView() -> AnyView? { nil }
    func expandedView() -> AnyView? { nil }
    func dashboardTile() -> AnyView? {
        AnyView(QuickTogglesDashboardTile(state: state, controller: self))
    }
    func wideBarView() -> AnyView? { nil }

    func activate() {
        snapshotState()

        // Dark mode changes come via distributed notification — zero cost vs polling.
        themeObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.state.darkMode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        }

        // Audio changes via workspace notification (fires on system volume/mute change).
        audioObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.sound.settingsChangedNotification"),
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.refreshMute()
        }
    }

    func deactivate() {
        if let themeObserver { DistributedNotificationCenter.default().removeObserver(themeObserver) }
        if let audioObserver { DistributedNotificationCenter.default().removeObserver(audioObserver) }
        themeObserver = nil
        audioObserver = nil
    }

    func refresh() async { snapshotState() }

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
        runOsascript("set volume output muted \(state.muted)")
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

    func toggleDoNotDisturb() {
        // Requires Accessibility permission. Check first and guide if not granted.
        guard AXIsProcessTrusted() else {
            let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            AXIsProcessTrustedWithOptions(opts)
            return
        }

        let script = """
        tell application "System Events"
            tell process "ControlCenter"
                try
                    if exists (menu bar item "Focus" of menu bar 1) then
                        click (menu bar item "Focus" of menu bar 1)
                        return
                    end if
                end try
                click (menu bar item "Control Center" of menu bar 1)
                delay 0.35
                try
                    set cc to window "Control Center"
                    set focusBtn to first button of cc whose description contains "Focus" or name contains "Focus"
                    click focusBtn
                    return
                end try
                key code 53
            end tell
        end tell
        """
        runOsascript(script)
        // Re-read state after a brief delay for the Focus menu bar item to appear/disappear.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.refreshDND()
        }
    }

    // MARK: - Private

    private func snapshotState() {
        state.darkMode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        state.caffeinated = caffeinateTask?.isRunning == true
        refreshMute()
        refreshDND()
    }

    private func refreshMute() {
        Task.detached(priority: .utility) { [weak self] in
            let script = "output muted of (get volume settings)"
            let result = Self.runScript(script)
            await MainActor.run { [weak self] in
                if let result { self?.state.muted = result.contains("true") }
            }
        }
    }

    private func refreshDND() {
        guard AXIsProcessTrusted() else { return }
        let script = """
        tell application "System Events"
            tell process "ControlCenter"
                return exists (menu bar item "Focus" of menu bar 1)
            end tell
        end tell
        """
        Task.detached(priority: .utility) { [weak self] in
            let result = Self.runScript(script)
            await MainActor.run { [weak self] in
                self?.state.dndActive = result?.contains("true") ?? false
            }
        }
    }

    @discardableResult
    private func runOsascript(_ source: String) -> String? { Self.runScript(source) }

    @discardableResult
    private nonisolated static func runScript(_ source: String) -> String? {
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
}
