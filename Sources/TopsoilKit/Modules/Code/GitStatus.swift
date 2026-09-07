import Foundation

/// Parsed result of `git status --porcelain=v1 --branch` for a repo.
public struct GitStatus: Equatable, Sendable {
    public var branch: String?     // nil when detached / not a repo
    public var isDirty: Bool
    public var ahead: Int
    public var behind: Int

    public init(branch: String?, isDirty: Bool, ahead: Int, behind: Int) {
        self.branch = branch
        self.isDirty = isDirty
        self.ahead = ahead
        self.behind = behind
    }

    public static let unknown = GitStatus(branch: nil, isDirty: false, ahead: 0, behind: 0)
}

/// Pure parser for `git status --porcelain=v1 --branch` output, so the parsing is
/// testable without invoking git.
public enum GitStatusParser {
    public static func parse(_ output: String) -> GitStatus {
        let lines = output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)

        guard let header = lines.first(where: { $0.hasPrefix("## ") }) else {
            return .unknown
        }

        let changeLines = lines.filter { !$0.hasPrefix("##") }
        let isDirty = !changeLines.isEmpty

        let info = String(header.dropFirst(3)) // strip "## "
        let branch = parseBranch(from: info)
        let ahead = parseCount(in: info, label: "ahead ")
        let behind = parseCount(in: info, label: "behind ")

        return GitStatus(branch: branch, isDirty: isDirty, ahead: ahead, behind: behind)
    }

    private static func parseBranch(from info: String) -> String? {
        if info.hasPrefix("HEAD (no branch)") { return nil }

        var name = info
        if let upstreamRange = name.range(of: "...") {
            name = String(name[name.startIndex..<upstreamRange.lowerBound])
        } else if let bracketRange = name.range(of: " [") {
            name = String(name[name.startIndex..<bracketRange.lowerBound])
        }
        name = name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? nil : name
    }

    private static func parseCount(in info: String, label: String) -> Int {
        guard let range = info.range(of: label) else { return 0 }
        let tail = info[range.upperBound...]
        let digits = tail.prefix { $0.isNumber }
        return Int(digits) ?? 0
    }
}
