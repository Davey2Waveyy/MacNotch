import MacNotchKit

func notchThemeTests() {
    test("theme tokens derive accent from appearance") {
        var appearance = NotchAppearance.defaults
        appearance.accentColor = .green
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: false)
        expectEqual(tokens.accentName, "green", "accent token name")
    }

    test("reduced motion overrides expressive motion") {
        var appearance = NotchAppearance.defaults
        appearance.motionStyle = .expressive
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: true)
        expectEqual(tokens.motionStyle, .reduced, "system reduced motion wins")
    }

    test("terminal preset uses precise corners") {
        var appearance = NotchAppearance.defaults
        appearance.preset = .terminal
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: false)
        expectEqual(tokens.cornerRadius, 6, "terminal corners")
    }
}
