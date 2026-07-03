import MacNotchKit

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

    test("default profiles map to expected appearance presets") {
        let profiles = WorkspaceProfile.defaults
        expectEqual(profiles[0].appearance.preset, .terminal, "coding preset")
        expectEqual(profiles[2].appearance.preset, .aurora, "music preset")
    }
}
