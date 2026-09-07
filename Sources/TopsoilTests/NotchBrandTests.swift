import TopsoilKit

func notchBrandTests() {
    test("NotchBrand exposes public product identity") {
        expectEqual(NotchBrand.productName, "Topsoil", "product name")
        expectEqual(NotchBrand.settingsTitle, "Topsoil Settings", "settings title")
        expectEqual(NotchBrand.quitMenuTitle, "Quit Topsoil", "quit menu title")
        // Internal identifiers stay legacy until the next major release (TCC + data migration).
        expectEqual(NotchBrand.bundleIdentifier, "io.notchapple.NotchApple", "bundle id")
        expectEqual(NotchBrand.applicationSupportDirectoryName, "NotchApple", "support directory")
        expectEqual(NotchBrand.legacyApplicationSupportDirectoryName, "MacNotch", "legacy support directory")
        expectEqual(NotchBrand.userAgent, "Topsoil/1.0", "user agent")
        expect(NotchBrand.affiliationDisclaimer.contains("not affiliated with Apple"), "affiliation disclaimer is explicit")
        expect(!NotchBrand.productName.localizedCaseInsensitiveContains("apple"), "product name carries no Apple mark")
        expect(!NotchBrand.productName.localizedCaseInsensitiveContains("mac"), "product name carries no Mac mark")
    }

    test("AppCore reads public brand values") {
        expectEqual(AppCore.displayName, "Topsoil", "display name")
        expectEqual(AppCore.bundleID, "io.notchapple.NotchApple", "bundle id")
    }
}
