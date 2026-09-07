import Foundation

public final class WorkspaceProfileStore {
    public private(set) var profiles: [WorkspaceProfile]

    public init(profiles: [WorkspaceProfile] = WorkspaceProfile.defaults) {
        self.profiles = profiles
    }

    public func profile(id: String) -> WorkspaceProfile? {
        profiles.first { $0.id == id }
    }
}
