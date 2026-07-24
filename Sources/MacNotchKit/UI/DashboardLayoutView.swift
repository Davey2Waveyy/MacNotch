import AppKit
import SwiftUI

// MARK: - Trackpad scroll-wheel reader

/// Transparent NSView overlay that captures horizontal two-finger swipe events
/// and forwards them as directional page changes.
private final class ScrollWheelNSView: NSView {
    var onSwipe: ((Int) -> Void)?       // -1 = prev, +1 = next
    private var accumulated: CGFloat = 0

    override func scrollWheel(with event: NSEvent) {
        accumulated += event.scrollingDeltaX

        let ended = event.phase == .ended || event.phase == .cancelled
            || event.momentumPhase == .ended || event.momentumPhase == .cancelled
        let threshold: CGFloat = 40

        if ended {
            if accumulated > threshold  { onSwipe?(-1) }
            if accumulated < -threshold { onSwipe?(1) }
            accumulated = 0
        } else if abs(accumulated) >= threshold && event.momentumPhase == [] {
            onSwipe?(accumulated > 0 ? -1 : 1)
            accumulated = 0
        }
    }
}

private struct ScrollWheelReader: View {
    let onSwipe: (Int) -> Void
    @Environment(\.notchSnapshotMode) private var snapshotMode

    var body: some View {
        if snapshotMode {
            Color.clear
        } else {
            ScrollWheelRepresentable(onSwipe: onSwipe)
        }
    }
}

private struct ScrollWheelRepresentable: NSViewRepresentable {
    let onSwipe: (Int) -> Void

    func makeNSView(context: Context) -> ScrollWheelNSView {
        let v = ScrollWheelNSView()
        v.onSwipe = onSwipe
        return v
    }

    func updateNSView(_ v: ScrollWheelNSView, context: Context) {
        v.onSwipe = onSwipe
    }
}

// MARK: - Dashboard layout

/// Horizontal-tile expanded layout shown when the notch is clicked.
/// Modules opt in by implementing `dashboardTile()`; others are skipped.
/// Shows 4 tiles per page with < > arrow navigation and two-finger swipe.
struct DashboardLayoutView: View {
    @Environment(\.notchTokens) private var tokens
    @EnvironmentObject private var model: NotchWindowModel
    let modules: [any NotchModule]
    let size: CGSize
    let activeMode: ExpansionMode
    var topInset: CGFloat = 0
    let onSwitchMode: (ExpansionMode) -> Void
    var isPinned: Bool = false
    var onTogglePin: () -> Void = {}
    var onExternalDrop: ([URL]) -> Void = { _ in }

    @State private var slideDirection: Int = 1   // +1 = forward (trailing→), -1 = back (←leading)

    /// Page state lives on the window model so external drivers (debug hook)
    /// can flip pages; this view still owns clamping and slide direction.
    private var page: Int { model.dashboardPage }

    private let tilesPerPage = 5
    private let headerHeight: CGFloat = 18
    private let baseTileSpacing: CGFloat = 10
    private let baseOuterPadding: CGFloat = 14

    private var tileSpacing: CGFloat { (baseTileSpacing * tokens.spacingScale).rounded() }
    private var outerPadding: CGFloat { (baseOuterPadding * tokens.spacingScale).rounded() }

    // Builds pages respecting isFullPageTile: full-page modules get their own
    // page so they can fill the full width; others are grouped up to tilesPerPage.
    private var pages: [[(id: String, view: AnyView)]] {
        var result: [[(id: String, view: AnyView)]] = []
        var current: [(id: String, view: AnyView)] = []

        for module in modules {
            guard let tile = module.dashboardTile() else { continue }
            let entry = (module.id, tile)

            if module.isFullPageTile {
                if !current.isEmpty { result.append(current); current = [] }
                result.append([entry])
            } else {
                current.append(entry)
                if current.count == tilesPerPage { result.append(current); current = [] }
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    private var pageCount: Int { max(1, pages.count) }

    private var pageTiles: [(id: String, view: AnyView)] {
        guard page < pages.count else { return [] }
        return pages[page]
    }

    var body: some View {
        VStack(spacing: 8) {
            header.frame(height: headerHeight)
            tilesArea.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, outerPadding)
        .padding(.top, topInset + 4)
        .padding(.bottom, 6)
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(ScrollWheelReader { dir in navigate(dir) })
        .urlDropTarget(onExternalDrop)
        // Clamp to a valid page if the module list shrinks (e.g. after a toggle).
        .onChange(of: pageCount) { _, newCount in
            if page >= newCount {
                withAnimation(tokens.panelAnimation) {
                    model.dashboardPage = max(0, newCount - 1)
                }
            }
        }
        // External page changes (debug hook) still get a directional slide.
        .onChange(of: model.dashboardPage) { old, new in
            if new != old { slideDirection = new > old ? 1 : -1 }
        }
    }

    // MARK: - Navigation

    private func navigate(_ dir: Int) {
        let target = page + dir
        guard target >= 0, target < pageCount else { return }
        slideDirection = dir
        withAnimation(tokens.panelAnimation) { model.dashboardPage = target }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Text(NotchBrand.productName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(tokens.textPrimary)
            Spacer()
            if pageCount > 1 { pageDots }
            Text(Self.dateLabel())
                .font(tokens.captionFont)
                .foregroundStyle(tokens.textQuaternary)
                .padding(.leading, 4)
            NotchIconButton(
                systemName: "menubar.rectangle",
                accessibilityLabel: "Switch to wide bar",
                size: 22, iconSize: 10
            ) { onSwitchMode(.wideBar) }
            // Dedicated NSView drag handle so moving the panel is explicit.
            WindowDragHandleView()
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "grip.horizontal")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(tokens.textQuaternary)
                        .allowsHitTesting(false)
                )
                .help("Drag panel")
            NotchIconButton(
                systemName: isPinned ? "pin.fill" : "pin",
                accessibilityLabel: isPinned ? "Unpin notch panel" : "Pin notch panel",
                size: 22, iconSize: 10,
                isActive: isPinned,
                action: onTogglePin
            )
        }
    }

    private var pageDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<pageCount, id: \.self) { i in
                Capsule()
                    .fill(i == page ? tokens.accent.opacity(0.95) : Color.white.opacity(0.18))
                    .frame(width: i == page ? 14 : 4, height: 3.5)
                    .animation(tokens.panelAnimation, value: page)
            }
        }
        // Decorative dots read as one element announcing the current page.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dashboard page \(page + 1) of \(pageCount)")
    }

    private static func dateLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: Date())
    }

    // MARK: - Tiles area

    private var tilesArea: some View {
        // 3pt gap keeps the arrows' padded (30pt) hit targets from overlapping
        // the tiles' hover edges on either side.
        HStack(spacing: 3) {
            navArrow(systemName: "chevron.left", enabled: page > 0) { navigate(-1) }

            ZStack {
                if pages.isEmpty {
                    Text("No dashboard tiles yet")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    tilesRow
                        .id(page)
                        .transition(pageTransition)
                }
            }
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            navArrow(systemName: "chevron.right", enabled: page < pageCount - 1) { navigate(1) }
        }
    }

    private var tilesRow: some View {
        HStack(spacing: tileSpacing) {
            ForEach(pageTiles, id: \.id) { tile in
                tile.view
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .dashboardTileSurface()
                    .transition(tileTransition)
            }
        }
        .animation(tokens.panelAnimation, value: pageTiles.map { $0.id })
    }

    private var tileTransition: AnyTransition {
        // Reduce Motion: fade tiles in/out instead of scaling them.
        guard tokens.motionStyle != .reduced else { return .opacity }
        return .asymmetric(
            insertion: .scale(scale: 0.90, anchor: .center).combined(with: .opacity),
            removal:   .scale(scale: 0.94, anchor: .center).combined(with: .opacity)
        )
    }

    private var pageTransition: AnyTransition {
        // Reduce Motion: cross-fade instead of sliding pages across the panel.
        guard tokens.motionStyle != .reduced else { return .opacity }
        // A short parallax nudge reads calmer than sliding the full panel width.
        let shift: CGFloat = 28
        return .asymmetric(
            insertion: .offset(x: slideDirection > 0 ? shift : -shift)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.985, anchor: .center)),
            removal: .offset(x: slideDirection > 0 ? -shift : shift)
                .combined(with: .opacity)
                .combined(with: .scale(scale: 0.985, anchor: .center))
        )
    }

    // MARK: - Nav arrows

    private func navArrow(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        let base = systemName == "chevron.left" ? "Previous dashboard page" : "Next dashboard page"
        return NotchIconButton(
            systemName: systemName,
            accessibilityLabel: enabled ? base : "\(base) unavailable",
            size: 22,
            iconSize: 10,
            action: action
        )
        .opacity(enabled ? 1 : 0)
        .disabled(!enabled)
        .animation(.easeOut(duration: 0.15), value: enabled)
    }

}
