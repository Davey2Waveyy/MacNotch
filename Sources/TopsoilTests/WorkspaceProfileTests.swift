import TopsoilKit

func workspaceProfileTests() {
    test("default profiles include public launch set") {
        let profiles = WorkspaceProfile.defaults
        expectEqual(profiles.map(\.id), ["coding", "focus", "music", "meetings", "personal"], "profile ids")
    }

    test("profile applies appearance and module enablement") {
        var settings = AppSettings.defaults
        let profile = WorkspaceProfile(
            id: "coding",
            name: "Coding",
            defaultExpansionMode: .dashboard,
            appearance: NotchAppearance.defaults,
            enabledModuleIDs: ["code", "timers", "shelf", "customize"]
        )
        profile.apply(to: &settings)
        expectEqual(settings.activeWorkspaceProfileID, "coding", "active profile")
        expectEqual(settings.defaultExpansionMode, .dashboard, "mode applied")
        expect(settings.modules.first { $0.id == "code" }?.isEnabled == true, "code enabled")
        expect(settings.modules.first { $0.id == "stocks" }?.isEnabled == false, "stocks disabled")
    }

    test("every default profile keeps recovery surfaces enabled") {
        for profile in WorkspaceProfile.defaults {
            expect(profile.enabledModuleIDs.contains("customize"), "\(profile.id) keeps customize")
            expect(profile.enabledModuleIDs.contains("commandPalette"), "\(profile.id) keeps commandPalette")
        }
    }

    test("matching identifies the active profile and any deviation") {
        var settings = AppSettings.defaults
        expect(WorkspaceProfile.matching(settings) == nil, "defaults are Custom")

        WorkspaceProfile.defaults.first { $0.id == "coding" }?.apply(to: &settings)
        expectEqual(WorkspaceProfile.matching(settings), "coding", "matches applied profile")

        var moduleDeviation = settings
        let i = moduleDeviation.modules.firstIndex { $0.id == "stocks" }!
        moduleDeviation.modules[i].isEnabled.toggle()
        expect(WorkspaceProfile.matching(moduleDeviation) == nil, "module toggle → Custom")

        var themeDeviation = settings
        themeDeviation.appearance.accentColor = .red
        expect(WorkspaceProfile.matching(themeDeviation) == nil, "theme change → Custom")

        var modeDeviation = settings
        modeDeviation.defaultExpansionMode = .wideBar
        expect(WorkspaceProfile.matching(modeDeviation) == nil, "mode change → Custom")
    }

    test("default profiles map to expected appearance presets") {
        let profiles = WorkspaceProfile.defaults
        expectEqual(profiles[0].appearance.preset, .terminal, "coding preset")
        expectEqual(profiles[2].appearance.preset, .aurora, "music preset")
    }
}
