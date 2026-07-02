import Foundation

public enum AppearancePreset: String, Codable, CaseIterable, Sendable {
    case studioGlass
    case minimalGraphite
    case aurora
    case terminal
    case paper

    public static let launchPresets: [AppearancePreset] = [
        .studioGlass, .minimalGraphite, .aurora, .terminal
    ]
}

public enum AccentColorChoice: String, Codable, CaseIterable, Sendable {
    case cyan, blue, purple, green, amber, red
}

public enum GlassIntensity: String, Codable, CaseIterable, Sendable {
    case subtle, balanced, vivid
}

public enum PanelDensity: String, Codable, CaseIterable, Sendable {
    case compact, comfortable, spacious
}

public enum CornerStyle: String, Codable, CaseIterable, Sendable {
    case precise, soft, pill
}

public enum MotionStyle: String, Codable, CaseIterable, Sendable {
    case expressive, calm, reduced
}

public enum DashboardLayoutPreference: String, Codable, CaseIterable, Sendable {
    case pagedTiles, priority, fullPageFocus
}

public enum MenuBarIconStyle: String, Codable, CaseIterable, Sendable {
    case monochrome, accent, hiddenWhenPossible
}

public struct NotchAppearance: Codable, Equatable, Sendable {
    public var preset: AppearancePreset
    public var accentColor: AccentColorChoice
    public var glassIntensity: GlassIntensity
    public var panelDensity: PanelDensity
    public var cornerStyle: CornerStyle
    public var motionStyle: MotionStyle
    public var dashboardLayout: DashboardLayoutPreference
    public var menuBarIconStyle: MenuBarIconStyle

    public init(preset: AppearancePreset,
                accentColor: AccentColorChoice,
                glassIntensity: GlassIntensity,
                panelDensity: PanelDensity,
                cornerStyle: CornerStyle,
                motionStyle: MotionStyle,
                dashboardLayout: DashboardLayoutPreference,
                menuBarIconStyle: MenuBarIconStyle) {
        self.preset = preset
        self.accentColor = accentColor
        self.glassIntensity = glassIntensity
        self.panelDensity = panelDensity
        self.cornerStyle = cornerStyle
        self.motionStyle = motionStyle
        self.dashboardLayout = dashboardLayout
        self.menuBarIconStyle = menuBarIconStyle
    }

    public static let defaults = NotchAppearance(
        preset: .studioGlass,
        accentColor: .cyan,
        glassIntensity: .balanced,
        panelDensity: .comfortable,
        cornerStyle: .soft,
        motionStyle: .expressive,
        dashboardLayout: .pagedTiles,
        menuBarIconStyle: .monochrome
    )
}
