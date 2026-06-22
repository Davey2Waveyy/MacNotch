import Foundation

/// One-click actions a pinned project row can perform.
public enum CodeAction: String, CaseIterable, Sendable {
    case claudeCode
    case editor
    case terminal
    case reveal
}

/// A resolved command to run (executable + arguments), built without executing so
/// the construction is testable.
public struct LaunchCommand: Equatable, Sendable {
    public var executable: String
    public var arguments: [String]

    public init(executable: String, arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }
}

public enum LaunchCommandBuilder {
    /// Builds the command for an action against a project `path`.
    /// `editorCLI` is the editor launcher on PATH (default `code` for VS Code).
    public static func command(for action: CodeAction, path: String, editorCLI: String = "code") -> LaunchCommand {
        switch action {
        case .editor:
            return LaunchCommand(executable: "/usr/bin/env", arguments: [editorCLI, path])
        case .terminal:
            return LaunchCommand(executable: "/usr/bin/open", arguments: ["-a", "Terminal", path])
        case .reveal:
            return LaunchCommand(executable: "/usr/bin/open", arguments: ["-R", path])
        case .claudeCode:
            let shellCommand = "cd \(shellSingleQuote(path)) && claude"
            let script = "tell application \"Terminal\"\nactivate\ndo script \"\(appleScriptEscape(shellCommand))\"\nend tell"
            return LaunchCommand(executable: "/usr/bin/osascript", arguments: ["-e", script])
        }
    }

    /// Wraps a path in single quotes, safely escaping embedded single quotes.
    public static func shellSingleQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Escapes a string for inclusion inside an AppleScript double-quoted literal.
    public static func appleScriptEscape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
