import TopsoilKit

func sanityTests() {
    test("AppCore version and bundle id") {
        expectEqual(AppCore.version, "0.1.0", "version")
        expectEqual(AppCore.bundleID, "io.notchapple.NotchApple", "bundleID")
    }
}
