import Foundation
import MacNotchKit

func settingsLogicTests() {
    test("settings: toggle flips a module's enabled flag") {
        var settings = AppSettings.defaults
        SettingsLogic.toggle(&settings, id: "media", on: false)
        expect(settings.modules.first { $0.id == "media" }?.isEnabled == false, "media disabled")
        SettingsLogic.toggle(&settings, id: "media", on: true)
        expect(settings.modules.first { $0.id == "media" }?.isEnabled == true, "media re-enabled")
    }

    test("settings: toggle ignores unknown ids") {
        var settings = AppSettings.defaults
        let before = settings.modules
        SettingsLogic.toggle(&settings, id: "nope", on: false)
        expect(settings.modules == before, "no change for unknown id")
    }

    test("settings: reorder moves the first module to the end") {
        var settings = AppSettings.defaults
        let firstID = settings.modules[0].id
        SettingsLogic.reorder(&settings, fromOffsets: IndexSet(integer: 0), toOffset: settings.modules.count)
        expect(settings.modules.last?.id == firstID, "first module is now last")
    }

    test("settings: launch-at-login persists only after a successful login-item update") {
        var settings = AppSettings.defaults
        let shouldPersist = SettingsLogic.applyLaunchAtLoginResult(
            &settings,
            requested: true,
            operationSucceeded: true,
            actualEnabled: false
        )

        expect(shouldPersist, "successful login-item update should persist")
        expect(settings.launchAtLogin, "launch-at-login follows the requested value on success")
    }

    test("settings: launch-at-login reverts to the real login-item state on failure") {
        var settings = AppSettings.defaults
        settings.launchAtLogin = false

        let shouldPersist = SettingsLogic.applyLaunchAtLoginResult(
            &settings,
            requested: true,
            operationSucceeded: false,
            actualEnabled: false
        )

        expect(!shouldPersist, "failed login-item update does not persist")
        expect(!settings.launchAtLogin, "launch-at-login reverts to the actual system state")
    }

    test("appearance mutations update settings") {
        var settings = AppSettings.defaults
        SettingsLogic.setAppearancePreset(&settings, preset: .terminal)
        SettingsLogic.setMotionStyle(&settings, motionStyle: .calm)
        SettingsLogic.setPanelDensity(&settings, density: .compact)
        SettingsLogic.setAccentColor(&settings, accentColor: .purple)
        SettingsLogic.setGlassIntensity(&settings, glassIntensity: .vivid)
        SettingsLogic.setCornerStyle(&settings, cornerStyle: .pill)
        expectEqual(settings.appearance.preset, .terminal, "preset changed")
        expectEqual(settings.appearance.motionStyle, .calm, "motion changed")
        expectEqual(settings.appearance.panelDensity, .compact, "density changed")
        expectEqual(settings.appearance.accentColor, .purple, "accent changed")
        expectEqual(settings.appearance.glassIntensity, .vivid, "glass intensity changed")
        expectEqual(settings.appearance.cornerStyle, .pill, "corner style changed")
    }
}
