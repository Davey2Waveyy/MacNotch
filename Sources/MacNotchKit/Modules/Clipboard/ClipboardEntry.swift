import Foundation

public struct ClipboardEntry: Codable, Identifiable, Sendable {
    public let id: UUID
    public let text: String
    public let copiedAt: Date

    public init(id: UUID = .init(), text: String, copiedAt: Date = .init()) {
        self.id = id
        self.text = text
        self.copiedAt = copiedAt
    }
}
