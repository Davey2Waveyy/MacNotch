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

private struct ScrollWheelReader: NSViewRepresentable {
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
    let modules: [any NotchModule]
    let size: CGSize
    let activeMode: ExpansionMode
    var topInset: CGFloat = 0
    let onSwitchMode: (ExpansionMode) -> Void
    var isPinned: Bool = false
    var onTogglePin: () -> Void = {}
    var onExternalDrop: ([URL]) -> Void = { _ in }

    @State private var page = 0
    @State private var slideDirection: Int = 1   // +1 = forward (trailing→), -1 = back (←leading)

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
        VStack(spacing: 6) {
            header.frame(height: headerHeight)
            tilesArea.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, outerPadding)
        .padding(.top, topInset + 4)
        .padding(.bottom, 4)
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(ScrollWheelReader { dir in navigate(dir) })
        .dropDestination(for: URL.self) { urls, _ in
            onExternalDrop(urls)
            return true
        }
        // Clamp to a valid page if the module list shrinks (e.g. after a toggle).
        .onChange(of: pageCount) { _, newCount in
            if page >= newCount {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                    page = max(0, newCount - 1)
                }
            }
        }
    }

    // MARK: - Navigation

    private func navigate(_ dir: Int) {
        let target = page + dir
        guard target >= 0, target < pageCount else { return }
        slideDirection = dir
        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) { page = target }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            Text(NotchBrand.productName)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(modeLabel)
                .font(.system(size: 8.5, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(tokens.accent)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(tokens.accent.opacity(0.15))
                        .overlay(Capsule().strokeBorder(tokens.accent.opacity(0.30), lineWidth: 0.5))
                )
            Spacer()
            if pageCount > 1 { pageDots }
            Text(Self.dateLabel())
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.40))
                .padding(.leading, 6)
            // Dedicated NSView drag handle so moving the panel is explicit.
            WindowDragHandleView()
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "grip.horizontal")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.40))
                        .allowsHitTesting(false)
                )
                .padding(.leading, 2)
                .help("Drag panel")
            Button(action: onTogglePin) {
                Image(systemName: isPinned ? "lock.fill" : "lock.open")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isPinned ? Color.white.opacity(0.85) : Color.white.opacity(0.30))
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isPinned ? Color.white.opacity(0.12) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPinned ? "Unpin notch panel" : "Pin notch panel")
            .help(isPinned ? "Unpin notch panel" : "Pin notch panel")
            .padding(.leading, 4)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<pageCount, id: \.self) { i in
                Capsule()
                    .fill(i == page ? tokens.accent : Color.white.opacity(0.20))
                    .frame(width: i == page ? 16 : 5, height: 4)
                    .shadow(color: i == page ? tokens.accent.opacity(0.5) : .clear,
                            radius: 4, x: 0, y: 0)
                    .animation(.spring(response: 0.28, dampingFraction: 0.78), value: page)
            }
        }
    }

    private var modeLabel: String {
        switch activeMode {
        case .compact:   return "QUICK"
        case .dashboard: return "QUICK"
        case .wideBar:   return "WIDE"
        }
    }

    private static func dateLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: Date())
    }

    // MARK: - Tiles area

    private var tilesArea: some View {
        HStack(spacing: 0) {
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
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.90, anchor: .center).combined(with: .opacity),
                            removal:   .scale(scale: 0.94, anchor: .center).combined(with: .opacity)
                        )
                    )
            }
            // Ghost spacers only on full pages to keep consistent tile widths.
            // Partial pages let tiles expand to fill the available space naturally.
            if pageTiles.count == tilesPerPage {
                // All slots filled — no ghost spacers needed.
                EmptyView()
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.80), value: pageTiles.map { $0.id })
    }

    private var pageTransition: AnyTransition {
        let insertEdge: Edge = slideDirection > 0 ? .trailing : .leading
        let removeEdge: Edge = slideDirection > 0 ? .leading  : .trailing
        return .asymmetric(
            insertion: .move(edge: insertEdge).combined(with: .opacity),
            removal:   .move(edge: removeEdge).combined(with: .opacity)
        )
    }

    // MARK: - Nav arrows

    private func navArrow(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        NotchIconButton(
            systemName: systemName,
            accessibilityLabel: systemName == "chevron.left" ? "Previous dashboard page" : "Next dashboard page",
            size: 20,
            iconSize: 10,
            action: action
        )
        .foregroundStyle(.white.opacity(0.55))
        .opacity(enabled ? 1 : 0)
        .disabled(!enabled)
        .animation(.easeOut(duration: 0.15), value: enabled)
    }

}
