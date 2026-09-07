import Foundation

/// One file/folder parked on the Drop Shelf, held as a security-scoped bookmark so
/// it survives relaunches and can be resolved back to its original location.
public struct ShelfItem: Codable, Equatable, Sendable {
    public var name: String
    public var bookmark: Data

    public init(name: String, bookmark: Data) {
        self.name = name
        self.bookmark = bookmark
    }
}
