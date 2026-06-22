import AppKit
import SwiftUI
import MacNotchKit

@MainActor
final class ActivatingModule: NotchModule {
    let id: String
    var title: String
    var isEnabled = true
    private(set) var activationCount = 0

    init(_ id: String) {
        self.id = id
        self.title = id
    }

    func collapsedView() -> AnyView? { nil }
    func expandedView() -> AnyView { AnyView(EmptyView()) }
    func activate() { activationCount += 1 }
    func deactivate() {}
    func refresh() async {}
}

func notchWindowTests() {
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
                expandedWidth: 280,
                expandedHeight: 320,
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
}
