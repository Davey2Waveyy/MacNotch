import AppKit

@MainActor
public enum MacNotchApp {
    public static func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
