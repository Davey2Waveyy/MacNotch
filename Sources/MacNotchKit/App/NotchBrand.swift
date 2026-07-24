import Foundation

public enum NotchBrand {
    public static let productName = "Topsoil"
    public static let settingsTitle = "Topsoil Settings"
    public static let quitMenuTitle = "Quit Topsoil"
    // Bundle ID and data directories intentionally keep the legacy identifiers:
    // changing them re-prompts every TCC permission and orphans user data.
    // Flip both at the next major release together with an AppDataMigrator step
    // (see docs/legal-review-2026-07-09.md).
    public static let bundleIdentifier = "io.notchapple.NotchApple"
    public static let applicationSupportDirectoryName = "NotchApple"
    public static let legacyApplicationSupportDirectoryName = "MacNotch"
    public static let userAgent = "Topsoil/1.0"
    public static let affiliationDisclaimer = "Topsoil is not affiliated with Apple Inc."
}
