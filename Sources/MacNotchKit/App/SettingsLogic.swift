import Foundation

/// Pure settings mutations, separated from the SwiftUI view so they can be tested.
public enum SettingsLogic {
    public static func toggle(_ settings: inout AppSettings, id: String, on: Bool) {
        guard let index = settings.modules.firstIndex(where: { $0.id == id }) else { return }
        settings.modules[index].isEnabled = on
    }

    /// Reorders using SwiftUI `.onMove` semantics (IndexSet + destination offset).
    public static func reorder(_ settings: inout AppSettings, fromOffsets: IndexSet, toOffset: Int) {
        settings.modules.move(fromOffsets: fromOffsets, toOffset: toOffset)
    }

    @discardableResult
    public static func applyLaunchAtLoginResult(
        _ settings: inout AppSettings,
        requested: Bool,
        operationSucceeded: Bool,
        actualEnabled: Bool
    ) -> Bool {
        if operationSucceeded {
            settings.launchAtLogin = requested
            return true
        }

        settings.launchAtLogin = actualEnabled
        return false
    }
}
