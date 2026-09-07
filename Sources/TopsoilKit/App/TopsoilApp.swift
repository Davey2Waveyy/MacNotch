import AppKit

@MainActor
public enum TopsoilApp {
    private static let appDelegate = AppDelegate()

    public static func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        app.delegate = appDelegate
        app.run()
    }
}
