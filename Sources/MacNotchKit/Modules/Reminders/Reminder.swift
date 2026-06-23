import Foundation

public struct Reminder: Codable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var isDone: Bool
    public let createdAt: Date

    public init(id: UUID = .init(), title: String, isDone: Bool = false, createdAt: Date = .init()) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
    }
}
