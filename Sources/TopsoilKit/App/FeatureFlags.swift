import Foundation

public enum FeatureCategory: String, Codable, Equatable, Sendable {
    case launchCore
    case launchOptional
    case creativeLabs
    case rejectedOrDeferred
}

public enum FeatureFlag: String, Codable, CaseIterable, Sendable {
    case workspaceProfiles
    case commandPalette
    case focusMode
    case aiWorkbench
    case dropActions
    case notificationTriage
    case meetingMode
    case clipboardStudio
    case systemPulse

    public var category: FeatureCategory {
        switch self {
        case .workspaceProfiles, .commandPalette:
            return .launchCore
        case .focusMode, .aiWorkbench, .dropActions:
            return .launchOptional
        case .notificationTriage, .meetingMode, .clipboardStudio, .systemPulse:
            return .creativeLabs
        }
    }
}

public struct FeatureFlags: Codable, Equatable, Sendable {
    public var enabled: Set<FeatureFlag>

    public init(enabled: Set<FeatureFlag>) {
        self.enabled = enabled
    }

    public static let defaults = FeatureFlags(enabled: [.workspaceProfiles, .commandPalette])

    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        enabled.contains(flag)
    }
}
