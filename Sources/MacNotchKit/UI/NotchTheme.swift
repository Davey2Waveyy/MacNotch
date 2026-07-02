import SwiftUI

/// Resolved theme values derived from `NotchAppearance` plus system state
/// (e.g. reduced motion) that views can read without knowing appearance rules.
public struct NotchThemeTokens: Equatable, Sendable {
    public var accentName: String
    public var cornerRadius: CGFloat
    public var tileCornerRadius: CGFloat
    public var glassOpacity: Double
    public var strokeOpacity: Double
    public var motionStyle: MotionStyle
}

/// Shared visual constants so the dashboard and wide-bar layouts stay in sync.
public enum NotchTheme {
    static let tileCornerRadius: CGFloat = 8
    static let tileFill     = Color.white.opacity(0.075)
    static let tileStroke   = Color.white.opacity(0.10)
    static let hairline     = Color.white.opacity(0.10)
    static let accent       = Color(red: 0.36, green: 0.78, blue: 1)

    /// Derives theme tokens from the user's appearance settings, folding in
    /// the system's reduced-motion preference (which always wins).
    public static func tokens(for appearance: NotchAppearance, reduceMotion: Bool) -> NotchThemeTokens {
        let resolvedMotion: MotionStyle = reduceMotion ? .reduced : appearance.motionStyle
        let presetCorner: CGFloat = appearance.preset == .terminal ? 6 : 8
        return NotchThemeTokens(
            accentName: appearance.accentColor.rawValue,
            cornerRadius: presetCorner,
            tileCornerRadius: presetCorner,
            glassOpacity: appearance.glassIntensity == .vivid ? 0.78 : 0.62,
            strokeOpacity: appearance.glassIntensity == .subtle ? 0.08 : 0.14,
            motionStyle: resolvedMotion
        )
    }

    // Kept for older tile callers that still want a subtle top-to-bottom tint.
    static func tileFillGradient(hovered: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(hovered ? 0.10 : 0.075),
                Color.white.opacity(hovered ? 0.08 : 0.060)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func tileStrokeGradient(hovered: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(hovered ? 0.18 : 0.10),
                Color.white.opacity(hovered ? 0.10 : 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Resolves a token's accent name to a concrete color. Falls back to the
    /// existing default accent for any name that isn't recognized.
    static func accentColor(for name: String) -> Color {
        switch name {
        case "blue": return Color(red: 0.36, green: 0.60, blue: 1.0)
        case "purple": return Color(red: 0.68, green: 0.45, blue: 1.0)
        case "green": return Color(red: 0.40, green: 0.85, blue: 0.55)
        case "amber": return Color(red: 1.0, green: 0.72, blue: 0.30)
        case "red": return Color(red: 1.0, green: 0.40, blue: 0.40)
        default: return accent // cyan / unrecognized
        }
    }
}
