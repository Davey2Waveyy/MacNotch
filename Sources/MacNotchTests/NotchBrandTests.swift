import MacNotchKit

func notchBrandTests() {
    test("NotchBrand exposes public product identity") {
        expectEqual(NotchBrand.productName, "NotchApple", "product name")
        expectEqual(NotchBrand.settingsTitle, "NotchApple Settings", "settings title")
        expectEqual(NotchBrand.quitMenuTitle, "Quit NotchApple", "quit menu title")
        expectEqual(NotchBrand.bundleIdentifier, "io.notchapple.NotchApple", "bundle id")
        expectEqual(NotchBrand.applicationSupportDirectoryName, "NotchApple", "new support directory")
        expectEqual(NotchBrand.legacyApplicationSupportDirectoryName, "MacNotch", "legacy support directory")
        expect(NotchBrand.affiliationDisclaimer.contains("not affiliated with Apple"), "affiliation disclaimer is explicit")
    }

    test("AppCore reads public brand values") {
        expectEqual(AppCore.displayName, "NotchApple", "display name")
        expectEqual(AppCore.bundleID, "io.notchapple.NotchApple", "bundle id")
    }
}
