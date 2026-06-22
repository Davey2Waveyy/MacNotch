import AppKit
import SwiftUI
import MacNotchKit

@MainActor
final class ActivatingModule: NotchModule {
    let id: String
    var title: String
    var isEnabled = true
    private(set) var activationCount = 0
    private(set) var deactivationCount = 0

    init(_ id: String) {
        self.id = id
        self.title = id
    }

    func collapsedView() -> AnyView? { nil }
    func expandedView() -> AnyView { AnyView(EmptyView()) }
    func activate() { activationCount += 1 }
    func deactivate() { deactivationCount += 1 }
    func refresh() async {}
}

@MainActor
private func makeTestWindow() -> NotchWindow {
    _ = NSApplication.shared
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension("json")
    return NotchWindow(registry: ModuleRegistry(), settings: SettingsStore(url: url))
}

@MainActor
private func notchWindowPanel(for window: NotchWindow) -> NSPanel {
    for child in Mirror(reflecting: window).children {
        if let panel = child.value as? NSPanel {
            return panel
        }
    }

    fatalError("NotchWindow panel not found")
}

@MainActor
private func notchWindowModel(for window: NotchWindow) -> NotchWindowModel {
    for child in Mirror(reflecting: window).children {
        if let model = child.value as? NotchWindowModel {
            return model
        }
    }

    fatalError("NotchWindow model not found")
}

@MainActor
private func currentNotchRect() -> CGRect {
    let screens = ScreenLocator.current()
    let screen = ScreenLocator.choose(from: screens)
        ?? ScreenInfo(
            frame: NSScreen.main?.frame ?? .zero,
            safeAreaTop: 0,
            notchWidth: nil,
            isMain: true
        )

    return ScreenLocator.notchRect(for: screen, defaultWidth: 200)
}

@MainActor
private func waitForMainQueue(_ duration: TimeInterval) {
    RunLoop.main.run(until: Date(timeIntervalSinceNow: duration))
}

@MainActor
private func hoverEnter(_ window: NotchWindow) {
    if let event = NSEvent.enterExitEvent(
        with: .mouseEntered,
        location: .zero,
        modifierFlags: [],
        timestamp: ProcessInfo.processInfo.systemUptime,
        windowNumber: 0,
        context: nil,
        eventNumber: 0,
        trackingNumber: 0,
        userData: nil
    ) {
        window.mouseEntered(with: event)
    } else {
        fatalError("Failed to create mouse-entered event")
    }
}

@MainActor
private func hoverExit(_ window: NotchWindow) {
    if let event = NSEvent.enterExitEvent(
        with: .mouseExited,
        location: .zero,
        modifierFlags: [],
        timestamp: ProcessInfo.processInfo.systemUptime,
        windowNumber: 0,
        context: nil,
        eventNumber: 0,
        trackingNumber: 0,
        userData: nil
    ) {
        window.mouseExited(with: event)
    } else {
        fatalError("Failed to create mouse-exited event")
    }
}

func notchWindowTests() {
    test("outside-click policy ignores clicks inside the panel and collapses active outside states") {
        let frame = CGRect(x: 100, y: 100, width: 280, height: 320)
        let inside = CGPoint(x: 140, y: 140)
        let outside = CGPoint(x: 40, y: 40)

        expect(
            !NotchWindowInputPolicy.shouldCollapseForOutsideClick(
                at: inside,
                panelFrame: frame,
                state: .expanded,
                phase: .idle
            ),
            "inside clicks do not collapse"
        )
        expect(
            !NotchWindowInputPolicy.shouldCollapseForOutsideClick(
                at: outside,
                panelFrame: frame,
                state: .collapsed,
                phase: .idle
            ),
            "collapsed state ignores outside clicks"
        )
        expect(
            NotchWindowInputPolicy.shouldCollapseForOutsideClick(
                at: outside,
                panelFrame: frame,
                state: .expanded,
                phase: .idle
            ),
            "expanded state collapses on outside click"
        )
        expect(
            NotchWindowInputPolicy.shouldCollapseForOutsideClick(
                at: outside,
                panelFrame: frame,
                state: .collapsing,
                phase: .collapseGrace
            ),
            "collapse grace accepts outside click"
        )
        expect(
            NotchWindowInputPolicy.shouldCollapseForOutsideClick(
                at: outside,
                panelFrame: frame,
                state: .collapsing,
                phase: .collapseAnimation
            ),
            "collapse animation accepts outside click"
        )
    }

    test("NotchWindowModel starts collapsed") {
        MainActor.assumeIsolated {
            let model = NotchWindowModel()
            expect(!model.isExpanded, "window model defaults to collapsed")
        }
    }

    test("NotchRootView can be constructed with empty modules") {
        MainActor.assumeIsolated {
            let model = NotchWindowModel()
            let view = NotchRootView(
                model: model,
                collapsedSize: CGSize(width: 200, height: 32),
                modules: { [] }
            )

            let body = view.body
            _ = body
            expect(true, "root view body is available")
        }
    }

    test("NotchWindow show activates enabled modules from settings order") {
        MainActor.assumeIsolated {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("json")
            let persisted = AppSettings(
                modules: [
                    ModuleSetting(id: "calendar", isEnabled: false),
                    ModuleSetting(id: "system", isEnabled: true),
                    ModuleSetting(id: "media", isEnabled: true),
                ],
                launchAtLogin: false
            )
            let data = try? JSONEncoder().encode(persisted)
            expect(data != nil, "settings test data encoded")
            try? data?.write(to: tempURL, options: .atomic)

            let settings = SettingsStore(url: tempURL)
            settings.load()

            let registry = ModuleRegistry()
            let media = ActivatingModule("media")
            let calendar = ActivatingModule("calendar")
            let system = ActivatingModule("system")
            registry.register(media)
            registry.register(calendar)
            registry.register(system)

            let window = NotchWindow(registry: registry, settings: settings)
            window.show()

            expectEqual(system.activationCount, 1, "first enabled module activated")
            expectEqual(media.activationCount, 1, "second enabled module activated")
            expectEqual(calendar.activationCount, 0, "disabled module not activated")
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    test("NotchWindow teardown deactivates modules it activated exactly once") {
        MainActor.assumeIsolated {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("json")
            let persisted = AppSettings(
                modules: [
                    ModuleSetting(id: "calendar", isEnabled: false),
                    ModuleSetting(id: "system", isEnabled: true),
                    ModuleSetting(id: "media", isEnabled: true),
                ],
                launchAtLogin: false
            )
            let data = try? JSONEncoder().encode(persisted)
            expect(data != nil, "settings test data encoded")
            try? data?.write(to: tempURL, options: .atomic)

            let settings = SettingsStore(url: tempURL)
            settings.load()

            let registry = ModuleRegistry()
            let media = ActivatingModule("media")
            let calendar = ActivatingModule("calendar")
            let system = ActivatingModule("system")
            registry.register(media)
            registry.register(calendar)
            registry.register(system)

            let window = NotchWindow(registry: registry, settings: settings)
            window.show()
            window.tearDown()
            window.tearDown()

            expectEqual(system.deactivationCount, 1, "first enabled module deactivates once")
            expectEqual(media.deactivationCount, 1, "second enabled module deactivates once")
            expectEqual(calendar.deactivationCount, 0, "disabled module never deactivates")
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    test("collapse grace keeps visual state expanded until grace elapses") {
        let coordinator = NotchWindowTransitionCoordinator()

        coordinator.sync(for: .expanded)
        coordinator.requestGracefulCollapse()
        coordinator.sync(for: .collapsing)

        expect(coordinator.isVisuallyExpanded, "visual state stays expanded during grace")
        expectEqual(coordinator.phase, .collapseGrace, "grace phase is active")

        expect(coordinator.advanceCollapseGrace(for: .collapsing), "grace advances into animation")
        expect(!coordinator.isVisuallyExpanded, "visual collapse starts after grace")
        expectEqual(coordinator.phase, .collapseAnimation, "collapse animation phase becomes active")
    }

    test("collapse grace is canceled by hover re-entry") {
        let coordinator = NotchWindowTransitionCoordinator()

        coordinator.sync(for: .expanded)
        coordinator.requestGracefulCollapse()
        coordinator.sync(for: .collapsing)
        coordinator.sync(for: .expanding)

        expect(coordinator.isVisuallyExpanded, "visual state remains expanded after re-entry")
        expectEqual(coordinator.phase, .idle, "pending collapse is canceled")
        expect(!coordinator.advanceCollapseGrace(for: .expanding), "stale grace callback has no effect")
    }

    test("immediate collapse and later sync remain sane") {
        let coordinator = NotchWindowTransitionCoordinator()

        coordinator.sync(for: .expanded)
        coordinator.requestImmediateCollapse()
        coordinator.sync(for: .collapsing)

        expect(!coordinator.isVisuallyExpanded, "immediate collapse starts visual collapse")
        expectEqual(coordinator.phase, .collapseAnimation, "animation phase is active")
        expect(coordinator.advanceCollapseAnimation(for: .collapsing), "animation completion is allowed")

        coordinator.sync(for: .collapsed)
        expect(!coordinator.isVisuallyExpanded, "collapsed sync keeps collapsed visuals")
        expectEqual(coordinator.phase, .idle, "phase resets after collapsed sync")
    }

    test("NotchWindow uses the collapsed notch footprint while collapsed") {
        MainActor.assumeIsolated {
            let window = makeTestWindow()
            let panel = notchWindowPanel(for: window)
            let notchRect = currentNotchRect()
            let frame = panel.frame

            expectEqual(frame.width, notchRect.width, "collapsed width matches notch width")
            expectEqual(frame.height, notchRect.height, "collapsed height matches notch height")
            expectEqual(frame.midX, notchRect.midX, "collapsed frame stays centered on notch")
            expectEqual(frame.maxY, notchRect.maxY, "collapsed frame top stays aligned to notch")
        }
    }

    test("NotchWindow hover exit keeps expanded footprint through grace then collapses visually") {
        MainActor.assumeIsolated {
            let window = makeTestWindow()
            let panel = notchWindowPanel(for: window)
            let model = notchWindowModel(for: window)
            let notchRect = currentNotchRect()

            hoverEnter(window)
            waitForMainQueue(0.4)

            expect(model.isExpanded, "hover enter expands the window")
            expectEqual(panel.frame.width, 280, "expanded width is applied")
            expectEqual(panel.frame.height, 320, "expanded height is applied")

            hoverExit(window)

            expect(model.isExpanded, "grace keeps visuals expanded immediately after exit")
            expectEqual(panel.frame.width, 280, "grace keeps expanded width")
            expectEqual(panel.frame.height, 320, "grace keeps expanded height")

            waitForMainQueue(0.25)

            expect(!model.isExpanded, "visual collapse starts after grace elapses")
            expectEqual(panel.frame.width, notchRect.width, "post-grace width collapses to notch width")
            expectEqual(panel.frame.height, notchRect.height, "post-grace height collapses to notch height")
        }
    }

    test("NotchWindow hover re-entry cancels stale grace and collapse completion callbacks") {
        MainActor.assumeIsolated {
            let window = makeTestWindow()
            let panel = notchWindowPanel(for: window)
            let model = notchWindowModel(for: window)

            hoverEnter(window)
            waitForMainQueue(0.4)

            hoverExit(window)
            waitForMainQueue(0.22)
            hoverEnter(window)
            waitForMainQueue(0.3)

            expect(model.isExpanded, "hover re-entry re-expands the window")
            expectEqual(panel.frame.width, 280, "re-entry restores expanded width")
            expectEqual(panel.frame.height, 320, "re-entry restores expanded height")

            waitForMainQueue(0.3)

            expect(model.isExpanded, "stale collapse completion cannot run after re-entry")
            expectEqual(panel.frame.width, 280, "stale completion leaves expanded width intact")
            expectEqual(panel.frame.height, 320, "stale completion leaves expanded height intact")
        }
    }

    test("NotchWindow toggle during collapse grace closes immediately") {
        MainActor.assumeIsolated {
            let window = makeTestWindow()
            let panel = notchWindowPanel(for: window)
            let model = notchWindowModel(for: window)
            let notchRect = currentNotchRect()

            hoverEnter(window)
            waitForMainQueue(0.45)
            hoverExit(window)

            expect(model.isExpanded, "grace keeps the window visually expanded before toggle")
            window.toggle()

            expect(!model.isExpanded, "toggle forces immediate visual collapse during grace")
            expectEqual(panel.frame.width, notchRect.width, "toggle restores collapsed width immediately")
            expectEqual(panel.frame.height, notchRect.height, "toggle restores collapsed height immediately")

            waitForMainQueue(0.35)

            expect(!model.isExpanded, "forced collapse remains closed after scheduled callbacks")
            expectEqual(panel.frame.width, notchRect.width, "scheduled callbacks leave collapsed width intact")
            expectEqual(panel.frame.height, notchRect.height, "scheduled callbacks leave collapsed height intact")
        }
    }

    test("NotchWindow toggle during collapse animation reopens immediately") {
        MainActor.assumeIsolated {
            let window = makeTestWindow()
            let panel = notchWindowPanel(for: window)
            let model = notchWindowModel(for: window)

            hoverEnter(window)
            waitForMainQueue(0.45)
            hoverExit(window)
            waitForMainQueue(0.25)

            expect(!model.isExpanded, "post-grace collapse animation is visually collapsed before toggle")
            window.toggle()

            expect(model.isExpanded, "toggle reopens immediately once the panel is visually collapsed")
            expectEqual(panel.frame.width, 280, "toggle restores expanded width immediately")
            expectEqual(panel.frame.height, 320, "toggle restores expanded height immediately")

            waitForMainQueue(0.3)

            expect(model.isExpanded, "stale collapse completion cannot re-close after reopening")
            expectEqual(panel.frame.width, 280, "stale collapse completion leaves expanded width intact")
            expectEqual(panel.frame.height, 320, "stale collapse completion leaves expanded height intact")
        }
    }
}
