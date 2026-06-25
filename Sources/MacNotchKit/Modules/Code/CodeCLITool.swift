import Foundation

public enum CodeCLITool: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case claude
    case codex
    case cursor

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .codex: return "Codex"
        case .cursor: return "Cursor"
        }
    }

    public var command: String { rawValue }

    /// The actual executable to launch. Note `cursor` (the app's bundled launcher)
    /// only opens the Cursor GUI — the interactive agent CLI is `cursor-agent`.
    public var executableName: String {
        switch self {
        case .claude: return "claude"
        case .codex: return "codex"
        case .cursor: return "cursor-agent"
        }
    }

    /// Shown in the terminal pane when the executable can't be found on PATH.
    public var missingHint: String {
        switch self {
        case .claude:
            return "claude not found on PATH.\nInstall Claude Code, then relaunch MacNotch."
        case .codex:
            return "codex not found on PATH.\nInstall the Codex CLI, then relaunch MacNotch."
        case .cursor:
            return "cursor-agent not found.\nInstall it with:  curl https://cursor.com/install -fsS | bash"
        }
    }

    var systemImage: String {
        switch self {
        case .claude: return "sparkles"
        case .codex: return "bolt.fill"
        case .cursor: return "cursorarrow.rays"
        }
    }

    public static func named(_ value: String) -> CodeCLITool? {
        CodeCLITool(rawValue: value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

public struct CodeTerminalPaneDescriptor: Equatable, Identifiable, Sendable {
    public var tool: CodeCLITool

    public init(tool: CodeCLITool) {
        self.tool = tool
    }

    public var id: String { tool.id }
    public var displayName: String { tool.displayName }
    public var command: String { tool.command }
    public var executableName: String { tool.executableName }

    public static let defaultPanes: [CodeTerminalPaneDescriptor] =
        CodeCLITool.allCases.map(CodeTerminalPaneDescriptor.init(tool:))
}

public enum CodeCLIResolver {
    public static func terminalEnvironment(
        from environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [String: String] {
        var resolved = environment
        let originalPath = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        let pathParts = orderedUnique(extraSearchPaths(homeDirectory: homeDirectory) + splitPath(originalPath))

        resolved["PATH"] = pathParts.joined(separator: ":")
        resolved["TERM"] = "xterm-256color"
        resolved["COLORTERM"] = "truecolor"
        return resolved
    }

    /// Absolute path to the tool's executable, or nil when it isn't installed.
    public static func resolvedExecutablePath(
        for tool: CodeCLITool,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        isExecutable: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    ) -> String? {
        let env = terminalEnvironment(from: environment, homeDirectory: homeDirectory)
        let searchPaths = splitPath(env["PATH"] ?? "")
        let pathCandidates = searchPaths.map { path in
            URL(fileURLWithPath: path).appendingPathComponent(tool.executableName).path
        } + fallbackExecutablePaths(for: tool, homeDirectory: homeDirectory)

        return orderedUnique(pathCandidates).first(where: isExecutable)
    }

    public static func resolvedShellCommand(
        for tool: CodeCLITool,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        isExecutable: (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) }
    ) -> String {
        guard let resolvedPath = resolvedExecutablePath(
            for: tool,
            environment: environment,
            homeDirectory: homeDirectory,
            isExecutable: isExecutable
        ) else {
            return tool.executableName
        }
        return shellWord(resolvedPath)
    }

    /// Quotes a value for safe inclusion in a shell command.
    public static func quoteForShell(_ value: String) -> String {
        shellWord(value)
    }

    private static func extraSearchPaths(homeDirectory: URL) -> [String] {
        [
            homeDirectory.appendingPathComponent(".local/bin").path,
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/Applications/Codex.app/Contents/Resources",
            "/Applications/Cursor.app/Contents/Resources/app/bin"
        ]
    }

    private static func fallbackExecutablePaths(for tool: CodeCLITool, homeDirectory: URL) -> [String] {
        switch tool {
        case .claude:
            return [
                homeDirectory.appendingPathComponent(".local/bin/claude").path,
                "/opt/homebrew/bin/claude",
                "/usr/local/bin/claude"
            ]
        case .codex:
            return [
                "/Applications/Codex.app/Contents/Resources/codex",
                homeDirectory.appendingPathComponent(".local/bin/codex").path,
                "/opt/homebrew/bin/codex",
                "/usr/local/bin/codex"
            ]
        case .cursor:
            return [
                homeDirectory.appendingPathComponent(".local/bin/cursor-agent").path,
                "/opt/homebrew/bin/cursor-agent",
                "/usr/local/bin/cursor-agent"
            ]
        }
    }

    private static func splitPath(_ value: String) -> [String] {
        value
            .split(separator: ":", omittingEmptySubsequences: true)
            .map(String.init)
    }

    private static func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for value in values where !value.isEmpty && seen.insert(value).inserted {
            result.append(value)
        }
        return result
    }

    private static func shellWord(_ value: String) -> String {
        let safeCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_/-.,:+@=")
        if value.unicodeScalars.allSatisfy({ safeCharacters.contains($0) }) {
            return value
        }
        return LaunchCommandBuilder.shellSingleQuote(value)
    }
}
