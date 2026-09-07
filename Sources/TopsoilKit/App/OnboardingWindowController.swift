import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController {
    private var window: NSWindow?

    func showIfNeeded(settings: AppSettings, onComplete: @escaping (OnboardingState) -> Void) {
        guard !settings.onboarding.hasCompletedFirstRun else { return }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to \(NotchBrand.productName)"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: OnboardingView(onComplete: { [weak self] state in
            // Close before completing: onComplete synchronously drops the last
            // strong reference to this controller, so weak self must resolve first.
            self?.window?.close()
            self?.window = nil
            onComplete(state)
        }))
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
