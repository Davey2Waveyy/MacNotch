import SwiftUI

/// Resolved theme values derived from `NotchAppearance` plus system state
/// (e.g. reduced motion) that views can read without knowing appearance rules.
public struct NotchThemeTokens: Equatable, Sendable {
    public var accent: Color                 // resolved user accent
    public var cornerRadius: CGFloat         // panel-level
    public var tileCornerRadius: CGFloat     // tile surfaces
    public var glassOpacity: Double          // panel material strength
    public var strokeOpacity: Double         // hairlines / tile strokes
    public var tileFillOpacity: Double       // tile background strength
    public var tileFillTint: Color           // hue of tile fill (white for neutral presets)
    public var backgroundTint: Color         // wash over the black panel (clear for most presets)
    public var fontDesign: Font.Design       // .monospaced for Terminal, .default otherwise
    public var spacingScale: CGFloat         // density multiplier
    public var motionStyle: MotionStyle

    /// nil when motion is reduced — feed straight into .animation(_:value:)
    public var hoverAnimation: Animation? { motionStyle == .reduced ? nil : .easeOut(duration: 0.12) }

    /// Panel/root state transitions (expand, collapse, page changes).
    /// Falls back to a quick fade-style ease when motion is reduced, matching
    /// the system Reduce Motion preference folded into `motionStyle`.
    public var panelAnimation: Animation {
        motionStyle == .reduced
            ? .easeOut(duration: 0.12)
            : .spring(response: 0.34, dampingFraction: 0.82)
    }

    /// Terminal reads as wireframe-on-black: stroke uses the accent, boosted.
    /// Every other preset uses a plain white hairline at `strokeOpacity`.
    /// `fontDesign == .monospaced` is the terminal preset's own signal, so it
    /// doubles as the check here rather than adding a redundant stored flag.
    /// Hover raises the opacity by +0.09 over the resting value.
    public func tileStrokeColor(hovered: Bool = false) -> Color {
        let isTerminal = fontDesign == .monospaced
        let base = isTerminal ? accent : Color.white
        var opacity = isTerminal ? strokeOpacity + 0.10 : strokeOpacity
        if hovered { opacity += 0.09 }
        return base.opacity(opacity)
    }

    /// Fill opacity is scaled by `glassOpacity / 0.62` so the Glass Intensity
    /// setting visibly affects tile fill (0.62 is the `.balanced` baseline,
    /// so `.balanced` renders identically to the unscaled value).
    /// Hover adds +0.025 before scaling.
    public func tileFillColor(hovered: Bool = false) -> Color {
        let opacity = tileFillOpacity + (hovered ? 0.025 : 0)
        return tileFillTint.opacity(opacity * glassOpacity / 0.62)
    }
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
        let cornerRadius: CGFloat
        if appearance.preset == .terminal {
            cornerRadius = 6
        } else {
            switch appearance.cornerStyle {
            case .precise: cornerRadius = 6
            case .soft: cornerRadius = 8
            case .pill: cornerRadius = 12
            }
        }

        let glassOpacity: Double
        switch appearance.glassIntensity {
        case .subtle: glassOpacity = 0.50
        case .balanced: glassOpacity = 0.62
        case .vivid: glassOpacity = 0.78
        }

        let spacingScale: CGFloat
        switch appearance.panelDensity {
        case .compact: spacingScale = 0.85
        case .comfortable: spacingScale = 1.0
        case .spacious: spacingScale = 1.2
        }

        let fontDesign: Font.Design = appearance.preset == .terminal ? .monospaced : .default
        let accent = accentColor(for: appearance.accentColor)

        var strokeOpacity: Double = appearance.glassIntensity == .subtle ? 0.08 : 0.14
        var tileFillOpacity: Double
        var tileFillTint: Color
        var backgroundTint: Color

        switch appearance.preset {
        case .studioGlass, .paper:
            tileFillOpacity = 0.070
            tileFillTint = .white
            backgroundTint = .clear
        case .minimalGraphite:
            tileFillOpacity = 0.045
            tileFillTint = .white
            backgroundTint = .clear
            strokeOpacity = min(strokeOpacity, 0.08)
        case .aurora:
            tileFillOpacity = 0.085
            tileFillTint = accent
            backgroundTint = accent.opacity(0.06)
        case .terminal:
            tileFillOpacity = 0.040
            tileFillTint = .white
            backgroundTint = .clear
        }

        return NotchThemeTokens(
            accent: accent,
            cornerRadius: cornerRadius,
            tileCornerRadius: cornerRadius,
            glassOpacity: glassOpacity,
            strokeOpacity: strokeOpacity,
            tileFillOpacity: tileFillOpacity,
            tileFillTint: tileFillTint,
            backgroundTint: backgroundTint,
            fontDesign: fontDesign,
            spacingScale: spacingScale,
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

    /// Resolves an accent choice to a concrete color.
    public static func accentColor(for choice: AccentColorChoice) -> Color {
        switch choice {
        case .cyan: return accent
        case .blue: return Color(red: 0.36, green: 0.60, blue: 1.0)
        case .purple: return Color(red: 0.68, green: 0.45, blue: 1.0)
        case .green: return Color(red: 0.40, green: 0.85, blue: 0.55)
        case .amber: return Color(red: 1.0, green: 0.72, blue: 0.30)
        case .red: return Color(red: 1.0, green: 0.40, blue: 0.40)
        }
    }
}

private struct NotchTokensKey: EnvironmentKey {
    static let defaultValue = NotchTheme.tokens(for: .defaults, reduceMotion: false)
}

extension EnvironmentValues {
    var notchTokens: NotchThemeTokens {
        get { self[NotchTokensKey.self] }
        set { self[NotchTokensKey.self] = newValue }
    }
}
