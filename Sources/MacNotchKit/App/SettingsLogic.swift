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

    public static func setAppearancePreset(_ settings: inout AppSettings, preset: AppearancePreset) {
        settings.appearance.preset = preset
    }

    public static func setMotionStyle(_ settings: inout AppSettings, motionStyle: MotionStyle) {
        settings.appearance.motionStyle = motionStyle
    }

    public static func setPanelDensity(_ settings: inout AppSettings, density: PanelDensity) {
        settings.appearance.panelDensity = density
    }

    public static func setAccentColor(_ settings: inout AppSettings, accentColor: AccentColorChoice) {
        settings.appearance.accentColor = accentColor
    }

    public static func setGlassIntensity(_ settings: inout AppSettings, glassIntensity: GlassIntensity) {
        settings.appearance.glassIntensity = glassIntensity
    }

    public static func setCornerStyle(_ settings: inout AppSettings, cornerStyle: CornerStyle) {
        settings.appearance.cornerStyle = cornerStyle
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
