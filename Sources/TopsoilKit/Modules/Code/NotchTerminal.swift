import AppKit
import Foundation
import SwiftTerm

/// A real VT/xterm terminal session, backed by SwiftTerm's `LocalProcessTerminalView`.
///
/// The previous implementation mirrored PTY bytes into a plain `NSTextView` after
/// stripping every ANSI escape — which cannot render full-screen TUIs like claude,
/// codex, or cursor-agent. SwiftTerm provides a complete emulator (cursor
/// addressing, alt-screen, colors, real keyboard input), so those agents run and
/// accept typing inside the notch.
@MainActor
public final class NotchTerminal: ObservableObject {
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var activeCLI: String?

    /// The emulator view embedded in SwiftUI. Persisted for the session's lifetime
    /// so the buffer and first-responder state survive view updates.
    public let terminalView: LocalProcessTerminalView

    private let delegateProxy = ProcessDelegateProxy()

    public init() {
        terminalView = LocalProcessTerminalView(frame: CGRect(x: 0, y: 0, width: 420, height: 260))
        delegateProxy.owner = self
        terminalView.processDelegate = delegateProxy
        applyAppearance()
    }

    private func applyAppearance() {
        terminalView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        terminalView.nativeForegroundColor = NSColor(srgbRed: 0.753, green: 0.792, blue: 0.961, alpha: 0.96) // #C0CAF5
        terminalView.nativeBackgroundColor = .clear
        terminalView.caretColor = NSColor(srgbRed: 0.49, green: 0.81, blue: 1.0, alpha: 0.95)               // #7DCFFF
        terminalView.selectedTextBackgroundColor = NSColor(srgbRed: 0.49, green: 0.81, blue: 1.0, alpha: 0.24)
        terminalView.installColors(Self.ansiPalette)
    }

    /// Soft, modern 16-colour ANSI palette (Tokyo-Night lineage, cyan-leaning to
    /// match the app accent) so claude / codex / cursor output reads as designed
    /// rather than raw-terminal default. Order: 8 normal, then 8 bright.
    private static let ansiPalette: [SwiftTerm.Color] = [
        0x2A2E3A, 0xF7768E, 0x9ECE6A, 0xE0AF68, 0x7AA2F7, 0xBB9AF7, 0x7DCFFF, 0xC0CAF5,
        0x545C7E, 0xFF8DA1, 0xB6E27F, 0xF0C989, 0x9DBDFF, 0xCDB4FF, 0xA4DBFF, 0xE7ECFF,
    ].map { hex in
        let r = UInt16((hex >> 16) & 0xFF), g = UInt16((hex >> 8) & 0xFF), b = UInt16(hex & 0xFF)
        return SwiftTerm.Color(red: r << 8 | r, green: g << 8 | g, blue: b << 8 | b)
    }

    // MARK: - Launch

    public func launch(tool: CodeCLITool) {
        let env = CodeCLIResolver.terminalEnvironment()
        guard let path = CodeCLIResolver.resolvedExecutablePath(for: tool, environment: env) else {
            presentMissingTool(tool)
            return
        }
        launch(command: CodeCLIResolver.quoteForShell(path), displayName: tool.displayName, environment: env)
    }

    public func launch(
        command: String,
        displayName: String,
        environment: [String: String] = CodeCLIResolver.terminalEnvironment()
    ) {
        GardenState.shared.onTerminalCommandRun()
        stop()
        activeCLI = displayName
        isRunning = true
        let envArray = environment.map { "\($0.key)=\($0.value)" }
        // An interactive login shell so ~/.zshrc (nvm/node, PATH, etc.) is sourced
        // before the CLI execs — required for codex's npx-based MCP servers.
        terminalView.startProcess(
            executable: "/bin/zsh",
            args: ["-ilc", command],
            environment: envArray
        )
    }

    // MARK: - I/O

    public func sendInput(_ text: String) {
        terminalView.send(txt: text)
    }

    public func sendInterrupt() { sendInput("\u{03}") }

    public func stop() {
        if isRunning { terminalView.terminate() }
        isRunning = false
        activeCLI = nil
    }

    /// Plain-text snapshot of the current viewport — for diagnostics and tests.
    public func snapshotText() -> String {
        let terminal = terminalView.getTerminal()
        let cols = terminal.cols
        let rows = terminal.rows
        guard cols > 0, rows > 0 else { return "" }
        return terminal.getText(
            start: Position(col: 0, row: 0),
            end: Position(col: cols - 1, row: rows - 1)
        )
    }

    private func presentMissingTool(_ tool: CodeCLITool) {
        activeCLI = tool.displayName
        isRunning = false
        terminalView.feed(text: tool.missingHint + "\r\n")
    }

    fileprivate func processDidTerminate() {
        GardenState.shared.onSessionCodeSplitClose()
        isRunning = false
    }

    /// Bridges SwiftTerm's (non-isolated) delegate callbacks onto the main actor.
    private final class ProcessDelegateProxy: NSObject, LocalProcessTerminalViewDelegate {
        weak var owner: NotchTerminal?

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            Task { @MainActor [weak owner] in owner?.processDidTerminate() }
        }
        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
    }
}
