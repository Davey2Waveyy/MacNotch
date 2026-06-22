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
}
