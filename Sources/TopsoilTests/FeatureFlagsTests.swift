import TopsoilKit

func featureFlagsTests() {
    test("launch core features are enabled by default") {
        let flags = FeatureFlags.defaults
        expect(flags.isEnabled(.workspaceProfiles), "workspace profiles enabled")
        expect(flags.isEnabled(.commandPalette), "command palette enabled")
    }

    test("launch optional and labs features are disabled by default") {
        let flags = FeatureFlags.defaults
        expect(!flags.isEnabled(.focusMode), "focus mode disabled")
        expect(!flags.isEnabled(.aiWorkbench), "ai workbench disabled")
        expect(!flags.isEnabled(.notificationTriage), "notification triage disabled")
    }

    test("feature categories match roadmap") {
        expectEqual(FeatureFlag.workspaceProfiles.category, .launchCore, "workspace profiles category")
        expectEqual(FeatureFlag.dropActions.category, .launchOptional, "drop actions category")
        expectEqual(FeatureFlag.systemPulse.category, .creativeLabs, "system pulse category")
    }
}
