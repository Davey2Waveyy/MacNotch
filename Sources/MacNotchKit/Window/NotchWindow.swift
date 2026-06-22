import AppKit
import SwiftUI

@MainActor
public final class NotchWindow: NSObject {
    private let panel: NSPanel
    private let model = NotchWindowModel()
    private let machine = NotchStateMachine()
    private let transitionCoordinator = NotchWindowTransitionCoordinator()
    private let registry: ModuleRegistry
    private let settings: SettingsStore
    private let expandedWidth: CGFloat = 280
    private let expandedHeight: CGFloat = 320
    private let expansionAnimationDuration: TimeInterval = 0.35
    private let collapseGraceDelay: TimeInterval = 0.18
    private let collapseAnimationDuration: TimeInterval = 0.2
    private var scheduledTransitionToken: UInt = 0

    public init(registry: ModuleRegistry, settings: SettingsStore) {
        self.registry = registry
        self.settings = settings

        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = false
        panel.hidesOnDeactivate = false

        let root = NotchRootView(
            model: model,
            expandedWidth: expandedWidth,
            expandedHeight: expandedHeight,
            collapsedSize: notchRect.size,
            modules: { [weak self] in self?.orderedModules() ?? [] }
        )
        panel.contentView = NSHostingView(rootView: root)
        installHoverTracking()
        sync()
    }

    public func show() {
        sync()
        for module in orderedModules() {
            module.activate()
        }
        panel.orderFrontRegardless()
    }

    public func toggle() {
        if machine.state == .collapsed {
            guard machine.clicked() else { return }
        } else {
            guard machine.forceCollapse() else { return }
            transitionCoordinator.requestImmediateCollapse()
        }
        sync()
    }

    @objc public func mouseEntered(with event: NSEvent) {
        applyHover(true)
    }

    @objc public func mouseExited(with event: NSEvent) {
        applyHover(false)
    }

    private var notchRect: CGRect {
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

    private func orderedModules() -> [any NotchModule] {
        registry.ordered(by: settings.orderedEnabledIDs())
    }

    private func updateFrame(visuallyExpanded: Bool) {
        let rect = notchRect
        let size = visuallyExpanded ? CGSize(width: expandedWidth, height: expandedHeight) : rect.size
        let frame = CGRect(
            x: rect.midX - (size.width / 2),
            y: rect.maxY - size.height,
            width: size.width,
            height: size.height
        )
        panel.setFrame(frame, display: true)
    }

    private func installHoverTracking() {
        guard let view = panel.contentView else { return }
        let area = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        view.addTrackingArea(area)
    }

    private func applyHover(_ inside: Bool) {
        guard machine.hoverChanged(inside) else { return }
        if !inside, machine.state == .collapsing {
            transitionCoordinator.requestGracefulCollapse()
        }
        sync()
    }

    private func sync() {
        scheduledTransitionToken &+= 1
        transitionCoordinator.sync(for: machine.state)
        model.isExpanded = transitionCoordinator.isVisuallyExpanded
        updateFrame(visuallyExpanded: transitionCoordinator.isVisuallyExpanded)

        switch machine.state {
        case .expanding:
            scheduleTransition(after: expansionAnimationDuration) { [weak self] in
                guard let self, self.machine.completeExpand() else { return }
                self.sync()
            }
        case .collapsing:
            switch transitionCoordinator.phase {
            case .collapseGrace:
                scheduleTransition(after: collapseGraceDelay) { [weak self] in
                    guard let self, self.transitionCoordinator.advanceCollapseGrace(for: self.machine.state) else { return }
                    self.sync()
                }
            case .collapseAnimation:
                scheduleTransition(after: collapseAnimationDuration) { [weak self] in
                    guard
                        let self,
                        self.transitionCoordinator.advanceCollapseAnimation(for: self.machine.state),
                        self.machine.completeCollapse()
                    else { return }
                    self.sync()
                }
            case .idle:
                break
            }
        case .collapsed, .expanded:
            break
        }
    }

    private func scheduleTransition(after delay: TimeInterval, _ block: @escaping @MainActor () -> Void) {
        let token = scheduledTransitionToken
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.scheduledTransitionToken == token else { return }
                block()
            }
        }
    }
}
