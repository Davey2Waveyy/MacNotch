import AppKit
import SwiftUI

// MARK: - Trackpad scroll-wheel reader

/// Pure paging decision for horizontal scroll, so the gesture tuning is unit-tested
/// without synthesizing NSEvents. Turns one page per trackpad swipe (as soon as a
/// clearly-horizontal gesture crosses the threshold, ignoring momentum), and once
/// per threshold for a plain mouse wheel that carries no phase.
public struct SwipePager {
    public var threshold: CGFloat
    private var x: CGFloat = 0
    private var y: CGFloat = 0
    private var fired = false

    public init(threshold: CGFloat = 28) { self.threshold = threshold }

    /// Feed one scroll sample; returns -1 (prev) or +1 (next) when a page should turn.
    public mutating func feed(dx: CGFloat, dy: CGFloat,
                              began: Bool, ended: Bool,
                              isMomentum: Bool, isGesture: Bool) -> Int? {
        if began { x = 0; y = 0; fired = false }
        x += dx
        y += dy

        var direction: Int?
        let canFire = isGesture ? (!isMomentum && !fired) : true
        if canFire, abs(x) >= threshold, abs(x) > abs(y) {
            direction = x > 0 ? -1 : 1
            fired = true
            if !isGesture { x = 0; y = 0 }   // mouse wheel: rearm for the next detent
        }
        if ended { x = 0; y = 0; fired = false }
        return direction
    }
}

/// Transparent NSView overlay that captures horizontal two-finger swipe events
/// (and horizontal mouse-wheel) and forwards them as directional page changes.
private final class ScrollWheelNSView: NSView {
    var onSwipe: ((Int) -> Void)?       // -1 = prev, +1 = next
    private var pager = SwipePager()

    override func scrollWheel(with event: NSEvent) {
        let isGesture = event.phase != [] || event.momentumPhase != []
        if let direction = pager.feed(
            dx: event.scrollingDeltaX,
            dy: event.scrollingDeltaY,
            began: event.phase == .began,
            ended: event.phase == .ended || event.phase == .cancelled,
            isMomentum: event.momentumPhase != [],
            isGesture: isGesture
        ) {
            onSwipe?(direction)
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

struct DashboardLayoutView: View {
    @Environment(\.notchSnapshotMode) private var snapshotMode
    @Environment(\.notchTokens) private var tokens
    @EnvironmentObject private var model: NotchWindowModel
    let modules: [any NotchModule]
    let size: CGSize
    let activeMode: ExpansionMode
    var topInset: CGFloat = 0
    let onSwitchMode: (ExpansionMode) -> Void
    var isPinned = false
    var onTogglePin: () -> Void = {}
    var onExternalDrop: ([URL]) -> Void = { _ in }

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var available: [DashboardModuleDescriptor] {
        modules.compactMap { module in
            guard module.dashboardTile() != nil else { return nil }
            return DashboardModuleDescriptor(id: module.id, title: module.title, isFullPage: module.isFullPageTile)
        }
    }
    private var pages: [[DashboardModuleDescriptor]] {
        DashboardNavigation.pages(modules: available, query: query, layout: model.appearance.dashboardLayout)
    }
    private var page: Int { DashboardNavigation.clampedPage(model.dashboardPage, count: pages.count) }
    private var current: [DashboardModuleDescriptor] { pages.isEmpty ? [] : pages[page] }

    var body: some View {
        VStack(spacing: 12) {
            header
            tilesArea
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .padding(.horizontal, 18 * tokens.spacingScale)
        .padding(.top, topInset + 8)
        .padding(.bottom, 12)
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(ScrollWheelReader { navigate($0) })
        .urlDropTarget(onExternalDrop)
        .onChange(of: query) { model.dashboardPage = 0 }
        .onChange(of: pages) { model.dashboardPage = DashboardNavigation.clampedPage(model.dashboardPage, count: pages.count) }
    }

    private var header: some View {
        HStack(spacing: 16) {
            HStack(spacing: 7) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(tokens.accent)
                Text(NotchBrand.productName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(tokens.textPrimary)
            }
            Rectangle().fill(tokens.textQuaternary.opacity(0.4)).frame(width: 1, height: 16)
            Group {
                if snapshotMode { pageTabs } else {
                    ScrollView(.horizontal, showsIndicators: false) { pageTabs }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            searchField
            NotchIconButton(systemName: "menubar.rectangle", accessibilityLabel: "Switch to wide bar",
                            size: 26, iconSize: 12) { onSwitchMode(.wideBar) }
            WindowDragHandleView()
                .frame(width: 22, height: 26)
                .overlay(Image(systemName: "grip.horizontal").font(tokens.captionFont)
                    .foregroundStyle(tokens.textSecondary).allowsHitTesting(false))
                .help("Drag to move Topsoil")
            NotchIconButton(systemName: isPinned ? "pin.fill" : "pin",
                            accessibilityLabel: isPinned ? "Unpin notch panel" : "Pin notch panel",
                            size: 26, iconSize: 12, isActive: isPinned, action: onTogglePin)
        }
        .frame(height: 30)
    }

    private var pageTabs: some View {
        HStack(spacing: 4) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, items in
                Button { select(index) } label: {
                    HStack(spacing: 5) {
                        if items.count == 1, let item = items.first {
                            Image(systemName: ModulePresentation.icon(for: item.id))
                        }
                        Text(DashboardNavigation.title(for: items, index: index)).lineLimit(1)
                    }
                    .font(tokens.labelFont)
                    .foregroundStyle(index == page ? tokens.textPrimary : tokens.textSecondary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 7).fill(index == page ? tokens.accent.opacity(0.17) : .clear))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(index == page ? .isSelected : [])
                .help(items.map(\.title).joined(separator: ", "))
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(tokens.textSecondary)
            if snapshotMode {
                Text("Find a tool").foregroundStyle(tokens.textSecondary)
                Spacer(minLength: 0)
            } else {
            TextField("Find a tool", text: $query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .accessibilityLabel("Search enabled tools")
                .onExitCommand { query = ""; searchFocused = false }
            }
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear tool search")
            }
        }
        .font(tokens.labelFont)
        .foregroundStyle(tokens.textPrimary)
        .padding(.horizontal, 9)
        .frame(width: 160, height: 28)
        .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.055)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(searchFocused ? tokens.accent : .white.opacity(0.09)))
    }

    @ViewBuilder
    private var tilesArea: some View {
        if current.isEmpty {
            VStack(spacing: 8) {
                ModuleEmptyStateView(title: query.isEmpty ? "Make room for your tools" : "No matching tools",
                                     message: query.isEmpty ? "Enable modules in Topsoil Settings to build your workspace." : "Try a name like music, files, or timer. Search includes enabled modules.",
                                     systemImage: query.isEmpty ? "square.grid.2x2" : "magnifyingglass")
                if !query.isEmpty {
                    Button("Clear search") { query = "" }.buttonStyle(.notchSoft)
                }
            }
        } else if current.count == 1, let item = current.first, !item.isFullPage,
                  let module = modules.first(where: { $0.id == item.id }), let tile = module.dashboardTile() {
            HStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: ModulePresentation.icon(for: item.id))
                        .font(.system(size: 24, weight: .light)).foregroundStyle(tokens.accent)
                    Text(item.title)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(tokens.textPrimary)
                    Text(ModulePresentation.description(for: item.id))
                        .font(.system(size: 13)).foregroundStyle(tokens.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: 280, alignment: .leading)
                tile.frame(maxWidth: 520, maxHeight: .infinity).dashboardTileSurface()
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            GeometryReader { geometry in
                let spacing: CGFloat = 10 * tokens.spacingScale
                let priority = model.appearance.dashboardLayout == .priority && current.count > 1
                let units = CGFloat(current.count) + (priority ? 0.5 : 0)
                let unitWidth = min(current.first?.isFullPage == true ? geometry.size.width : (current.count < 3 ? 460 : 360), max(0, (geometry.size.width - spacing * CGFloat(current.count - 1)) / units))
                HStack(spacing: spacing) {
                    ForEach(current, id: \.id) { item in
                        if let module = modules.first(where: { $0.id == item.id }), let tile = module.dashboardTile() {
                            tile
                                .frame(width: unitWidth * (priority && item.id == current.first?.id ? 1.5 : 1), height: geometry.size.height)
                                .dashboardTileSurface()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .id(current.map(\.id))
            .transition(.opacity)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                .foregroundStyle(tokens.textSecondary)
            if isPinned {
                Text("·  Pinned").foregroundStyle(tokens.textTertiary)
            }
            Spacer()
            NotchIconButton(systemName: "chevron.left", accessibilityLabel: "Previous dashboard page", size: 22, iconSize: 9) { navigate(-1) }
                .disabled(page == 0)
                .keyboardShortcut("[", modifiers: .command)
            Text("\(pages.isEmpty ? 0 : page + 1) / \(pages.count)")
                .monospacedDigit().foregroundStyle(tokens.textSecondary)
                .accessibilityLabel("Page \(pages.isEmpty ? 0 : page + 1) of \(pages.count)")
            NotchIconButton(systemName: "chevron.right", accessibilityLabel: "Next dashboard page", size: 22, iconSize: 9) { navigate(1) }
                .disabled(page >= pages.count - 1)
                .keyboardShortcut("]", modifiers: .command)
        }
        .font(tokens.captionFont)
        .frame(height: 18)
    }

    private func select(_ target: Int) {
        withAnimation(tokens.panelAnimation) { model.dashboardPage = target }
    }

    private func navigate(_ direction: Int) {
        let target = page + direction
        guard pages.indices.contains(target) else { return }
        select(target)
    }
}
