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
}
