import Foundation
import MacNotchKit

func notchAppearanceTests() {
    test("default appearance is Studio Glass") {
        let appearance = NotchAppearance.defaults
        expectEqual(appearance.preset, .studioGlass, "default preset")
        expectEqual(appearance.motionStyle, .expressive, "default motion")
        expectEqual(appearance.panelDensity, .comfortable, "default density")
    }

    test("built-in presets expose launch set in order") {
        expectEqual(
            AppearancePreset.launchPresets,
            [.studioGlass, .minimalGraphite, .aurora, .terminal],
            "launch presets"
        )
    }

    test("appearance round-trips through AppSettings") {
        var settings = AppSettings.defaults
        settings.appearance = NotchAppearance(
            preset: .terminal,
            accentColor: .green,
            glassIntensity: .vivid,
            panelDensity: .compact,
            cornerStyle: .precise,
            motionStyle: .calm,
            dashboardLayout: .priority,
            menuBarIconStyle: .monochrome
        )
        let data = try! JSONEncoder().encode(settings)
        let decoded = try! JSONDecoder().decode(AppSettings.self, from: data)
        expectEqual(decoded.appearance.preset, .terminal, "preset persists")
        expectEqual(decoded.appearance.motionStyle, .calm, "motion persists")
    }

    test("legacy settings without appearance use defaults") {
        let legacyJSON = """
        {"modules":[{"id":"media","isEnabled":true}],"launchAtLogin":false,"defaultExpansionMode":"dashboard"}
        """
        let decoded = try! JSONDecoder().decode(AppSettings.self, from: Data(legacyJSON.utf8))
        expectEqual(decoded.appearance, .defaults, "legacy appearance fallback")
    }
}
