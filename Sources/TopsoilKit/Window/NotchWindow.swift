import AppKit
import Combine
import SwiftUI

/// Thin NSView wrapper that reliably owns its own tracking area.
/// NSHostingView manages tracking areas internally and can clobber externally-added
/// areas when SwiftUI re-renders, so we wrap it in this container instead.
@MainActor
private final class HoverContainerView: NSView {
    weak var owner: NotchWindow?
    var onDropped: (([URL]) -> Void)?

    private var hoverTrackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        // Keep one tracking area. AppKit follows the visible bounds during resize;
        // replacing it on every layout creates synthetic enter/exit sequences.
        guard hoverTrackingArea == nil else { return }
        let area = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        hoverTrackingArea = area
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) { owner?.mouseEntered(with: event) }
    override func mouseExited(with event: NSEvent) { owner?.mouseExited(with: event) }

    // MARK: - NSDraggingDestination
    // NSTrackingArea events are suppressed by the OS during a drag session, so we
    // register as a drag destination to detect drags entering the collapsed notch.

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        owner?.applyDragHover(true)
        owner?.updateMovability(dragInProgress: true)
        return .copy
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        .copy
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        // When the drag moves to a child (e.g. SwiftUI drop zone), AppKit calls
        // draggingExited on us even though the drag is still within our bounds.
        // Only collapse if the drag has truly left the panel.
        guard let sender else {
            owner?.applyDragHover(false)
            owner?.updateMovability(dragInProgress: false)
            return
        }
        let localPoint = convert(sender.draggingLocation, from: nil)
        if !bounds.contains(localPoint) {
            owner?.applyDragHover(false)
            owner?.updateMovability(dragInProgress: false)
        }
    }

    override func draggingEnded(_ sender: any NSDraggingInfo) {
        owner?.updateMovability(dragInProgress: false)
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        let urls = sender.draggingPasteboard
            .readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])?
            .compactMap { $0 as? URL } ?? []
        onDropped?(urls)
        owner?.updateMovability(dragInProgress: false)
        return !urls.isEmpty
    }
}

/// NSPanel that doesn't let AppKit reshape its frame to fit visibleFrame.
/// The notch panel intentionally hugs the very top of the screen and must
/// overlap the menu bar; the default constraint would push it down and clip
/// the expanded panel's height to whatever vertical space remains.
private final class UnconstrainedPanel: NSPanel {
    /// Fired when Escape reaches the panel (via the responder chain's
    /// `cancelOperation`) so the owner can collapse the expanded notch.
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}

@MainActor
public final class NotchWindow: NSObject {
    private let pointerLocation: () -> CGPoint
    private let panel: UnconstrainedPanel
    private let model = NotchWindowModel()
    private let machine = NotchStateMachine()
    private let transitionCoordinator = NotchWindowTransitionCoordinator()
    private let registry: ModuleRegistry
    private let settings: SettingsStore
    private let compactSize = CGSize(width: 280, height: 320)
    private let dashboardSize = CGSize(width: 1120, height: 350)
    private let wideBarRowHeight: CGFloat = 40
    /// Matches NotchRootView.wideBarTopInset so the SwiftUI content and the panel
    /// frame agree on the wide-bar height.
    private var wideBarTopInset: CGFloat { max(NSScreen.main?.safeAreaInsets.top ?? 0, 24) }
    private let minCompactHeight: CGFloat = 132
    private let maxCompactHeight: CGFloat = 520
    private var measuredCompactHeight: CGFloat = 320
    private var isShown = false
    private var compactHeightObserver: AnyCancellable?
    private var dashboardPageObserver: AnyCancellable?
    private let expansionAnimationDuration: TimeInterval = 0.35
    private let collapseGraceDelay: TimeInterval = 0.18
    private let collapseAnimationDuration: TimeInterval = 0.2
    private var scheduledTransitionToken: UInt = 0
    private var activeModules: [any NotchModule] = []
    private var isDragInProgress = false
    private var localClickMonitor: Any?
    private var globalClickMonitor: Any?
    private var globalMouseMoveMonitor: Any?
    private var localMouseMoveMonitor: Any?
    private var timerFiredObserver: Any?

    public init(registry: ModuleRegistry, settings: SettingsStore,
                pointerLocation: @escaping () -> CGPoint = { NSEvent.mouseLocation }) {
        self.pointerLocation = pointerLocation
        self.registry = registry
        self.settings = settings

        panel = UnconstrainedPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        super.init()

        // Escape closes the expanded panel when it is key (e.g. after a click
        // opened the dashboard). Same collapse path as an outside click.
        panel.onEscape = { [weak self] in self?.collapseForEscape() }

        machine.defaultExpandMode = settings.settings.defaultExpansionMode
        panel.isFloatingPanel = true
        // .statusBar (25) can render behind the macOS 26 menu bar on some
        // configurations. Use popUpMenu (101) which is the standard level for
        // system-overlay panels that need to appear above the menu bar.
        panel.level = .popUpMenu
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        // Allow text fields (e.g. the Reminders input) to grab keyboard focus on
        // click without making the whole panel key for routine hover interactions.
        panel.becomesKeyOnlyIfNeeded = true
        panel.worksWhenModal = true

        let root = NotchRootView(
            model: model,
            collapsedSize: notchRect.size,
            modules: { [weak self] in self?.orderedModules() ?? [] },
            onPanelTap: { [weak self] in self?.handlePanelTap() },
            onSwitchMode: { [weak self] mode in self?.setMode(mode) },
            onTogglePin: { [weak self] in self?.togglePin() },
            onOpenDashboard: { [weak self] in self?.openDashboard() },
            onExternalDrop: { [weak self] urls in self?.handleExternalDrop(urls) }
        )
        let hostingView = NSHostingView(rootView: root)
        // Use autoresizing — NOT autolayout — so the panel's frame is driven by
        // panel.setFrame() in `updateFrame`. With autolayout constraints, AppKit
        // calls `_changeWindowFrameFromConstraintsIfNecessary` to shrink the
        // window to fit the SwiftUI content's intrinsic size, which clobbers the
        // expanded panel height back down to whatever the compact preview wants.
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.autoresizingMask = [.width, .height]
        let container = HoverContainerView()
        container.owner = self
        container.onDropped = { [weak self] urls in self?.handleExternalDrop(urls) }
        container.registerForDraggedTypes([.fileURL])
        hostingView.frame = container.bounds
        container.addSubview(hostingView)
        panel.contentView = container
        compactHeightObserver = model.$compactContentHeight.sink { [weak self] height in
            MainActor.assumeIsolated { self?.applyCompactHeight(height) }
        }
        // The dashboard panel height depends on which page is showing, so resize
        // when the page changes (paged tiles / focus pages have different heights).
        dashboardPageObserver = model.$dashboardPage.sink { [weak self] _ in
            MainActor.assumeIsolated { self?.applyDashboardPageChange() }
        }
        installClickMonitorsIfNeeded()
        timerFiredObserver = NotificationCenter.default.addObserver(
            forName: .topsoilTimerFired, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.popOpenForAlarm() }
        }
        sync()
        model.appearance = settings.settings.appearance
        model.settings = settings.settings
    }

    /// Pops the notch open to the dashboard so a fired timer's alarm is visible.
    private func popOpenForAlarm() {
        guard machine.state == .collapsed || machine.mode != .dashboard else { return }
        if machine.state == .collapsed {
            _ = machine.tapped()
        } else {
            _ = machine.switchMode(to: .dashboard)
        }
        sync()
    }

    public func show() {
        installClickMonitorsIfNeeded()
        isShown = true
        installMouseMoveMonitorIfNeeded()
        applyCompactHeight(model.compactContentHeight)
        sync()
        activateModulesIfNeeded()
        panel.orderFrontRegardless()
    }

    /// Resizes the compact panel to hug the SwiftUI-measured content height so
    /// the preview never shows dead space below short content. Gated on `show()`
    /// so headless tests keep the fixed footprint they assert against.
    private func applyCompactHeight(_ height: CGFloat) {
        guard isShown else { return }
        let clamped = min(max(height, minCompactHeight), maxCompactHeight)
        guard abs(clamped - measuredCompactHeight) > 0.5 else { return }
        measuredCompactHeight = clamped
        if machine.mode == .compact, transitionCoordinator.isVisuallyExpanded {
            updateFrame(visuallyExpanded: true)
        }
    }

    /// Resizes the dashboard panel when the visible page changes, so tool-only
    /// pages shrink and rich/full-page pages restore full height.
    private func applyDashboardPageChange() {
        guard isShown, machine.mode == .dashboard, transitionCoordinator.isVisuallyExpanded else { return }
        updateFrame(visuallyExpanded: true)
    }

    public func tearDown() {
        isShown = false
        scheduledTransitionToken &+= 1
        deactivateModulesIfNeeded()
        removeClickMonitors()
        removeMouseMoveMonitor()
        if let timerFiredObserver {
            NotificationCenter.default.removeObserver(timerFiredObserver)
            self.timerFiredObserver = nil
        }
        panel.orderOut(nil)
    }

    /// Re-applies the enabled/ordered module set after a settings change and forces
    /// the SwiftUI tree to re-read the module list.
    public func reload() {
        machine.defaultExpandMode = settings.settings.defaultExpansionMode
        model.appearance = settings.settings.appearance
        model.settings = settings.settings
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
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKey()
        } else {
            guard machine.forceCollapse() else { return }
            transitionCoordinator.requestImmediateCollapse()
        }
        sync()
    }

    /// Scriptable control for captures/debugging, driven by the
    /// `com.notchapple.debug` distributed notification (see AppDelegate).
    /// Commands reuse the exact state-machine paths real input takes, so
    /// recordings show genuine transitions.
    public func debugPerform(_ command: String) {
        let parts = command.split(separator: " ")
        switch parts.first.map(String.init) {
        case "hover":
            if machine.hoverChanged(true) { sync() }
        case "expand":
            if machine.state == .collapsed || machine.state == .collapsing {
                _ = machine.clicked()
            } else {
                _ = machine.switchMode(to: .dashboard)
            }
            sync()
        case "widebar":
            if machine.switchMode(to: .wideBar) { sync() }
        case "collapse":
            if machine.forceCollapse() {
                transitionCoordinator.requestImmediateCollapse()
                sync()
            }
        case "pin":
            model.isPinned = true
        case "unpin":
            model.isPinned = false
        case "page":
            guard parts.count > 1, let target = Int(parts[1]) else { return }
            withAnimation(.spring(response: 0.36, dampingFraction: 0.80)) {
                model.dashboardPage = max(0, target)
            }
        default:
            break
        }
    }

    /// Handles a click directly on the notch panel. Unlike `toggle()`, a click on
    /// the hover (compact) preview promotes it to the full dashboard instead of
    /// collapsing — so a single click always lands you on the dashboard.
    public func handlePanelTap() {
        // Pinned panels don't collapse on background taps.
        if model.isPinned, machine.state == .expanding || machine.state == .expanded { return }
        switch machine.tapped() {
        case .opening, .promoting:
            // Dashboard mode hosts text fields (e.g. Add reminder). They can only
            // receive keystrokes when the app is active and the panel is key.
            NSApp.activate(ignoringOtherApps: true)
            panel.makeKey()
            sync()
        case .collapsing:
            transitionCoordinator.requestImmediateCollapse()
            sync()
        case .noChange:
            break
        }
    }

    @objc public func mouseEntered(with event: NSEvent) {
        checkMousePosition()
    }

    @objc public func mouseExited(with event: NSEvent) {
        // An exit can belong to pre-resize bounds or window-level changes.
        // The current screen-space position is authoritative, not the event type.
        checkMousePosition()
    }

    private func installMouseMoveMonitorIfNeeded() {
        if globalMouseMoveMonitor == nil {
            globalMouseMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.isShown else { return }
                    self.checkMousePosition()
                }
            }
        }
        if localMouseMoveMonitor == nil {
            localMouseMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
                MainActor.assumeIsolated {
                    guard let self, self.isShown else { return }
                    self.checkMousePosition()
                }
                return event
            }
        }
    }

    private func removeMouseMoveMonitor() {
        if let monitor = globalMouseMoveMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMoveMonitor = nil
        }
        if let monitor = localMouseMoveMonitor {
            NSEvent.removeMonitor(monitor)
            localMouseMoveMonitor = nil
        }
    }

    private func checkMousePosition() {
        guard !model.isPinned, !isDragInProgress else { return }
        // Click-opened workspaces are explicitly dismissed. Hover only manages
        // the collapsed notch and the compact preview, including its grace period.
        guard machine.state == .collapsed || machine.mode == .compact else { return }
        applyHover(panel.frame.contains(pointerLocation()))
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
            return CGSize(width: compactSize.width, height: measuredCompactHeight)
        case .dashboard:
            let descriptors = activeModules.compactMap { module -> DashboardModuleDescriptor? in
                guard module.dashboardTile() != nil else { return nil }
                return DashboardModuleDescriptor(id: module.id, title: module.title, isFullPage: module.isFullPageTile)
            }
            let height = DashboardNavigation.height(
                modules: descriptors,
                page: model.dashboardPage,
                layout: settings.settings.appearance.dashboardLayout
            )
            return CGSize(width: dashboardSize.width, height: height)
        case .wideBar:
            let screenWidth = ScreenLocator.choose(from: ScreenLocator.current())?.frame.width
                ?? NSScreen.main?.frame.width
                ?? 1440
            return CGSize(width: screenWidth, height: wideBarTopInset + wideBarRowHeight)
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

    fileprivate func updateMovability(dragInProgress: Bool) {
        isDragInProgress = dragInProgress
        // Window movement is handled exclusively by WindowDragHandleView so
        // isMovableByWindowBackground stays false — chip drags can't compete.
    }

    private func togglePin() {
        model.isPinned.toggle()
        if !model.isPinned {
            if machine.mode == .compact, machine.state == .expanded {
                let cursorInPanel = panel.frame.contains(pointerLocation())
                if !cursorInPanel {
                    _ = machine.hoverChanged(false)
                    transitionCoordinator.requestGracefulCollapse()
                    sync()
                }
            }
        }
    }

    private func openDashboard() {
        if machine.state == .collapsed || machine.state == .collapsing {
            _ = machine.tapped()   // tapped() opens into defaultExpandMode (.dashboard)
        } else {
            _ = machine.switchMode(to: .dashboard)
        }
        model.isPinned = false
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKey()
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
        guard !model.isPinned else { return }

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

    /// Escape is an explicit dismissal, so it collapses even a pinned panel.
    private func collapseForEscape() {
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
        // While pinned any expanded mode ignores hover-out.
        if !inside, model.isPinned { return }
        guard machine.hoverChanged(inside) else { return }
        if !inside {
            // Keep both monitors alive through grace so re-entry can cancel it.
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

        // Hover must remain above the menu bar across the entire camera island.
        // Only click-opened workspaces drop to floating for native file dragging.
        panel.level = transitionCoordinator.isVisuallyExpanded && machine.mode != .compact
            ? .floating : .popUpMenu

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
                    guard let self else { return }
                    if self.panel.frame.contains(self.pointerLocation()), !self.isDragInProgress {
                        self.applyHover(true)
                        return
                    }
                    guard self.transitionCoordinator.advanceCollapseGrace(for: self.machine.state) else { return }
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
