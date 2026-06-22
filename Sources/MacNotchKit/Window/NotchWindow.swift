import AppKit
import SwiftUI

/// Thin NSView wrapper that reliably owns its own tracking area.
/// NSHostingView manages tracking areas internally and can clobber externally-added
/// areas when SwiftUI re-renders, so we wrap it in this container instead.
@MainActor
private final class HoverContainerView: NSView {
    weak var owner: NotchWindow?
    var onDropped: (([URL]) -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) { owner?.mouseEntered(with: event) }
    override func mouseExited(with event: NSEvent) { owner?.mouseExited(with: event) }

    // MARK: - NSDraggingDestination
    // NSTrackingArea events are suppressed by the OS during a drag session, so we
    // register as a drag destination to detect drags entering the collapsed notch.

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        owner?.applyDragHover(true)
        return .copy
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        // When the drag moves to a child (e.g. SwiftUI drop zone), AppKit calls
        // draggingExited on us even though the drag is still within our bounds.
        // Only collapse if the drag has truly left the panel.
        guard let sender else { owner?.applyDragHover(false); return }
        let localPoint = convert(sender.draggingLocation, from: nil)
        if !bounds.contains(localPoint) {
            owner?.applyDragHover(false)
        }
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let urls = sender.draggingPasteboard
            .readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])?
            .compactMap { $0 as? URL } ?? []
        onDropped?(urls)
        return !urls.isEmpty
    }
}

@MainActor
public final class NotchWindow: NSObject {
    private let panel: NSPanel
    private let model = NotchWindowModel()
    private let machine = NotchStateMachine()
    private let transitionCoordinator = NotchWindowTransitionCoordinator()
    private let registry: ModuleRegistry
    private let settings: SettingsStore
    private let compactSize = CGSize(width: 280, height: 320)
    private let dashboardSize = CGSize(width: 720, height: 180)
    private let wideBarHeight: CGFloat = 56
    private let expansionAnimationDuration: TimeInterval = 0.35
    private let collapseGraceDelay: TimeInterval = 0.18
    private let collapseAnimationDuration: TimeInterval = 0.2
    private var scheduledTransitionToken: UInt = 0
    private var activeModules: [any NotchModule] = []
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?

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
            collapsedSize: notchRect.size,
            modules: { [weak self] in self?.orderedModules() ?? [] },
            onPanelTap: { [weak self] in self?.toggle() },
            onSwitchMode: { [weak self] mode in self?.setMode(mode) }
        )
        let hostingView = NSHostingView(rootView: root)
        let container = HoverContainerView()
        container.owner = self
        container.onDropped = { [weak self] urls in self?.handleExternalDrop(urls) }
        container.registerForDraggedTypes([.fileURL])
        hostingView.autoresizingMask = [.width, .height]
        container.addSubview(hostingView)
        panel.contentView = container
        installClickMonitorsIfNeeded()
        sync()
    }

    public func show() {
        installClickMonitorsIfNeeded()
        sync()
        activateModulesIfNeeded()
        panel.orderFrontRegardless()
    }

    public func tearDown() {
        scheduledTransitionToken &+= 1
        deactivateModulesIfNeeded()
        removeClickMonitors()
        panel.orderOut(nil)
    }

    /// Re-applies the enabled/ordered module set after a settings change and forces
    /// the SwiftUI tree to re-read the module list.
    public func reload() {
        deactivateModulesIfNeeded()
        activateModulesIfNeeded()
        model.objectWillChange.send()
    }

    public func toggle() {
        let canReopenFromCollapseAnimation =
            machine.state == .collapsing
            && transitionCoordinator.phase == .collapseAnimation
            && !transitionCoordinator.isVisuallyExpanded

        if machine.state == .collapsed || canReopenFromCollapseAnimation {
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

    private func activateModulesIfNeeded() {
        guard activeModules.isEmpty else { return }

        let modules = orderedModules()
        activeModules = modules
        for module in modules {
            module.activate()
        }
    }

    private func deactivateModulesIfNeeded() {
        guard !activeModules.isEmpty else { return }

        for module in activeModules {
            module.deactivate()
        }
        activeModules.removeAll(keepingCapacity: false)
    }

    private func expandedSize(for mode: ExpansionMode) -> CGSize {
        switch mode {
        case .compact:
            return compactSize
        case .dashboard:
            return dashboardSize
        case .wideBar:
            let screenWidth = ScreenLocator.choose(from: ScreenLocator.current())?.frame.width
                ?? NSScreen.main?.frame.width
                ?? 1440
            return CGSize(width: screenWidth, height: wideBarHeight)
        }
    }

    private func updateFrame(visuallyExpanded: Bool) {
        let rect = notchRect
        let size: CGSize
        let originX: CGFloat
        if visuallyExpanded {
            let target = expandedSize(for: machine.mode)
            size = target
            originX = machine.mode == .wideBar
                ? (NSScreen.main?.frame.minX ?? 0)
                : rect.midX - (target.width / 2)
        } else {
            size = rect.size
            originX = rect.midX - (size.width / 2)
        }
        let frame = CGRect(
            x: originX,
            y: rect.maxY - size.height,
            width: size.width,
            height: size.height
        )
        panel.setFrame(frame, display: true)
    }

    public func setMode(_ mode: ExpansionMode) {
        guard machine.switchMode(to: mode) else { return }
        sync()
    }

    private func installClickMonitorsIfNeeded() {
        let eventMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        if localClickMonitor == nil {
            localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.handleMonitoredClick(event)
                }
                return event
            }
        }

        if globalClickMonitor == nil {
            globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
                Task { @MainActor [weak self] in
                    self?.handleMonitoredClick(event)
                }
            }
        }
    }

    private func removeClickMonitors() {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }

        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
    }

    private func handleMonitoredClick(_ event: NSEvent) {
        guard panel.isVisible else { return }

        let screenPoint = screenPoint(for: event)
        guard NotchWindowInputPolicy.shouldCollapseForOutsideClick(
            at: screenPoint,
            panelFrame: panel.frame,
            state: machine.state,
            phase: transitionCoordinator.phase
        ) else { return }

        guard machine.forceCollapse() else { return }
        transitionCoordinator.requestImmediateCollapse()
        sync()
    }

    private func screenPoint(for event: NSEvent) -> CGPoint {
        if let window = event.window {
            return window.convertToScreen(CGRect(origin: event.locationInWindow, size: .zero)).origin
        }
        return event.locationInWindow
    }

    private func applyHover(_ inside: Bool) {
        guard machine.hoverChanged(inside) else { return }
        if !inside, machine.state == .collapsing {
            transitionCoordinator.requestGracefulCollapse()
        }
        sync()
    }

    fileprivate func applyDragHover(_ inside: Bool) {
        applyHover(inside)
    }

    private func handleExternalDrop(_ urls: [URL]) {
        (activeModules.first { $0.id == "shelf" } as? ShelfModule)?.acceptDrop(urls)
    }

    private func sync() {
        scheduledTransitionToken &+= 1
        transitionCoordinator.sync(for: machine.state)
        model.isExpanded = transitionCoordinator.isVisuallyExpanded
        model.mode = machine.mode
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
