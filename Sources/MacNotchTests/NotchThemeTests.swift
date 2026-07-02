import SwiftUI
import MacNotchKit

func notchThemeTests() {
    test("theme tokens derive accent from appearance") {
        var appearance = NotchAppearance.defaults
        appearance.accentColor = .green
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: false)
        expectEqual(tokens.accent, NotchTheme.accentColor(for: .green), "accent token color")
    }

    test("reduced motion overrides expressive motion") {
        var appearance = NotchAppearance.defaults
        appearance.motionStyle = .expressive
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: true)
        expectEqual(tokens.motionStyle, .reduced, "system reduced motion wins")
    }

    test("reduced motion yields nil hoverAnimation") {
        var appearance = NotchAppearance.defaults
        appearance.motionStyle = .expressive
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: true)
        expectEqual(tokens.hoverAnimation == nil, true, "hoverAnimation nil when reduced")
    }

    test("terminal preset uses precise corners") {
        var appearance = NotchAppearance.defaults
        appearance.preset = .terminal
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: false)
        expectEqual(tokens.cornerRadius, 6, "terminal corners")
    }

    test("corner style drives radius: precise 6, soft 8, pill 12") {
        var appearance = NotchAppearance.defaults
        appearance.preset = .studioGlass

        appearance.cornerStyle = .precise
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).cornerRadius, 6, "precise corner radius")

        appearance.cornerStyle = .soft
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).cornerRadius, 8, "soft corner radius")

        appearance.cornerStyle = .pill
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).cornerRadius, 12, "pill corner radius")
    }

    test("terminal preset overrides cornerStyle to 6 regardless") {
        var appearance = NotchAppearance.defaults
        appearance.preset = .terminal
        appearance.cornerStyle = .pill
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: false)
        expectEqual(tokens.cornerRadius, 6, "terminal always uses 6")
    }

    test("glass intensity yields three distinct opacities") {
        var appearance = NotchAppearance.defaults

        appearance.glassIntensity = .subtle
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).glassOpacity, 0.50, "subtle glass opacity")

        appearance.glassIntensity = .balanced
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).glassOpacity, 0.62, "balanced glass opacity")

        appearance.glassIntensity = .vivid
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).glassOpacity, 0.78, "vivid glass opacity")
    }

    test("panel density drives spacing scale: compact 0.85, comfortable 1.0, spacious 1.2") {
        var appearance = NotchAppearance.defaults

        appearance.panelDensity = .compact
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).spacingScale, 0.85, "compact spacing scale")

        appearance.panelDensity = .comfortable
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).spacingScale, 1.0, "comfortable spacing scale")

        appearance.panelDensity = .spacious
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).spacingScale, 1.2, "spacious spacing scale")
    }

    test("terminal preset uses monospaced font design, studioGlass uses default") {
        var appearance = NotchAppearance.defaults

        appearance.preset = .terminal
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).fontDesign, .monospaced, "terminal font design")

        appearance.preset = .studioGlass
        expectEqual(NotchTheme.tokens(for: appearance, reduceMotion: false).fontDesign, .default, "studioGlass font design")
    }

    test("aurora tints tiles with accent and washes background; studioGlass stays clear") {
        var appearance = NotchAppearance.defaults

        appearance.preset = .aurora
        let auroraTokens = NotchTheme.tokens(for: appearance, reduceMotion: false)
        expectEqual(auroraTokens.tileFillTint, auroraTokens.accent, "aurora tile fill tint matches accent")
        expectEqual(auroraTokens.backgroundTint == .clear, false, "aurora background tint is not clear")

        appearance.preset = .studioGlass
        let studioTokens = NotchTheme.tokens(for: appearance, reduceMotion: false)
        expectEqual(studioTokens.backgroundTint, .clear, "studioGlass background tint stays clear")
    }

    test("glass intensity scales tile fill opacity: vivid differs from balanced") {
        var appearance = NotchAppearance.defaults

        appearance.glassIntensity = .balanced
        let balancedTokens = NotchTheme.tokens(for: appearance, reduceMotion: false)

        appearance.glassIntensity = .vivid
        let vividTokens = NotchTheme.tokens(for: appearance, reduceMotion: false)

        expectEqual(vividTokens.tileFillColor(hovered: false) == balancedTokens.tileFillColor(hovered: false), false,
                     "vivid tile fill differs from balanced tile fill")
    }
}
