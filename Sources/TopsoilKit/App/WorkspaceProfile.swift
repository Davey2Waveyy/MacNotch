import Foundation

public struct WorkspaceProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var defaultExpansionMode: ExpansionMode
    public var appearance: NotchAppearance
    public var enabledModuleIDs: [String]

    public init(id: String,
                name: String,
                defaultExpansionMode: ExpansionMode,
                appearance: NotchAppearance,
                enabledModuleIDs: [String]) {
        self.id = id
        self.name = name
        self.defaultExpansionMode = defaultExpansionMode
        self.appearance = appearance
        self.enabledModuleIDs = enabledModuleIDs
    }

    public static let defaults: [WorkspaceProfile] = [
        WorkspaceProfile(id: "coding", name: "Coding", defaultExpansionMode: .dashboard, appearance: .defaults(preset: .terminal, accentColor: .green), enabledModuleIDs: ["code", "timers", "shelf", "customize", "commandPalette"]),
        WorkspaceProfile(id: "focus", name: "Focus", defaultExpansionMode: .compact, appearance: .defaults(preset: .minimalGraphite), enabledModuleIDs: ["timers", "pomodoro", "reminders", "calendar", "customize", "commandPalette"]),
        WorkspaceProfile(id: "music", name: "Music", defaultExpansionMode: .wideBar, appearance: .defaults(preset: .aurora, accentColor: .purple), enabledModuleIDs: ["media", "quickToggles", "shelf", "customize", "commandPalette"]),
        WorkspaceProfile(id: "meetings", name: "Meetings", defaultExpansionMode: .dashboard, appearance: .defaults, enabledModuleIDs: ["calendar", "reminders", "timers", "quickToggles", "customize", "commandPalette"]),
        WorkspaceProfile(id: "personal", name: "Personal", defaultExpansionMode: .dashboard, appearance: .defaults(preset: .studioGlass, accentColor: .amber), enabledModuleIDs: ["media", "stocks", "screenTime", "launcher", "customize", "commandPalette"])
    ]

    /// The profile whose modules, appearance, and default mode all match the
    /// current settings, or nil when the user has deviated — the picker shows
    /// "Custom" for nil. Derived so any deviation flips to Custom, instead of
    /// trusting a stored id that individual setters have to remember to clear.
    public static func matching(_ settings: AppSettings) -> String? {
        let enabled = Set(settings.modules.filter(\.isEnabled).map(\.id))
        return defaults.first { profile in
            profile.appearance == settings.appearance
                && profile.defaultExpansionMode == settings.defaultExpansionMode
                && Set(profile.enabledModuleIDs) == enabled
        }?.id
    }

    public func apply(to settings: inout AppSettings) {
        let enabled = Set(enabledModuleIDs)
        settings.activeWorkspaceProfileID = id
        settings.defaultExpansionMode = defaultExpansionMode
        settings.appearance = appearance
        for index in settings.modules.indices {
            settings.modules[index].isEnabled = enabled.contains(settings.modules[index].id)
        }
    }
}

private extension NotchAppearance {
    /// `.defaults` with a profile-specific preset/accent, keeping every other knob standard.
    static func defaults(preset: AppearancePreset,
                         accentColor: AccentColorChoice = NotchAppearance.defaults.accentColor) -> NotchAppearance {
        var appearance = NotchAppearance.defaults
        appearance.preset = preset
        appearance.accentColor = accentColor
        return appearance
    }
}
