import Foundation

/// Runs `git` to read a repo's status. Thin integration wrapper over the tested
/// `GitStatusParser`; returns `.unknown` for non-repos or any failure.
public enum GitProbe {
    public static func status(atPath path: String) -> GitStatus {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git", "-C", path, "status", "--porcelain=v1", "--branch"]

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return .unknown
        }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return .unknown }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        return GitStatusParser.parse(String(data: data, encoding: .utf8) ?? "")
    }
}
