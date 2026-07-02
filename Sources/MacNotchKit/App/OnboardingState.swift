import Foundation

public struct OnboardingState: Codable, Equatable, Sendable {
    public var hasCompletedFirstRun: Bool
    public var completedVersion: String?

    public init(hasCompletedFirstRun: Bool, completedVersion: String?) {
        self.hasCompletedFirstRun = hasCompletedFirstRun
        self.completedVersion = completedVersion
    }

    public static let defaults = OnboardingState(
        hasCompletedFirstRun: false,
        completedVersion: nil
    )
}
