import Foundation

/// A pinned project folder, held as a security-scoped bookmark so it survives
/// relaunches.
public struct CodeProject: Codable, Equatable, Sendable {
    public var name: String
    public var bookmark: Data

    public init(name: String, bookmark: Data) {
        self.name = name
        self.bookmark = bookmark
    }
}
