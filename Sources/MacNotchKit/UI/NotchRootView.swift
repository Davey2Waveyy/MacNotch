import AppKit
import Combine
import SwiftUI

/// Reports the intrinsic height of the compact-mode content so the panel can
/// hug its content instead of using a fixed height (which leaves dead space).
struct CompactContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

@MainActor
public final class NotchWindowModel: ObservableObject {
    @Published public var isExpanded = false
    @Published public var mode: ExpansionMode = .compact
    /// Intrinsic height of the compact-mode content, measured by the view tree.
    @Published public var compactContentHeight: CGFloat = 320
    /// When true the compact preview stays pinned open even after the cursor leaves.
    @Published public var isPinned = false

    public init() {}
}

public struct NotchRootView: View {
    @ObservedObject private var model: NotchWindowModel
    private let collapsedSize: CGSize
    private let modules: () -> [any NotchModule]
    private let onPanelTap: () -> Void
    private let onSwitchMode: (ExpansionMode) -> Void
    private let onTogglePin: () -> Void
    private let onOpenDashboard: () -> Void
    private let onExternalDrop: ([URL]) -> Void

    private let compactWidth: CGFloat = 280
    private static let minCompactHeight: CGFloat = 132
    private static let maxCompactHeight: CGFloat = 520
    private let dashboardSize = CGSize(width: 1340, height: 296)
    private let wideBarHeight: CGFloat = 56

    public init(
        model: NotchWindowModel,
        collapsedSize: CGSize,
        modules: @escaping () -> [any NotchModule],
        onPanelTap: @escaping () -> Void = {},
        onSwitchMode: @escaping (ExpansionMode) -> Void = { _ in },
        onTogglePin: @escaping () -> Void = {},
        onOpenDashboard: @escaping () -> Void = {},
        onExternalDrop: @escaping ([URL]) -> Void = { _ in }
    ) {
        self.model = model
        self.collapsedSize = collapsedSize
        self.modules = modules
        self.onPanelTap = onPanelTap
        self.onSwitchMode = onSwitchMode
        self.onTogglePin = onTogglePin
        self.onOpenDashboard = onOpenDashboard
        self.onExternalDrop = onExternalDrop
    }

    public var body: some View {
        panelBody
            .animation(.spring(response: 0.34, dampingFraction: 0.82), value: model.isExpanded)
            .animation(.spring(response: 0.32, dampingFraction: 0.84), value: model.mode)
            .animation(.spring(response: 0.30, dampingFraction: 0.86), value: model.compactContentHeight)
            .onPreferenceChange(CompactContentHeightKey.self) { height in
                guard height > 1 else { return }
                let clamped = min(max(height, Self.minCompactHeight), Self.maxCompactHeight)
                Task { @MainActor [model] in
                    if abs(clamped - model.compactContentHeight) > 0.5 {
                        model.compactContentHeight = clamped
                    }
                }
            }
    }

    private var expandedSize: CGSize {
        switch model.mode {
        case .compact: return CGSize(width: compactWidth, height: model.compactContentHeight)
        case .dashboard: return dashboardSize
        case .wideBar:
            let width = ScreenLocator.choose(from: ScreenLocator.current())?.frame.width
                ?? NSScreen.main?.frame.width
                ?? 1440
            return CGSize(width: width, height: wideBarHeight)
        }
    }

    private var panelBody: some View {
        let currentModules = modules()
        let size = expandedSize
        let width = model.isExpanded ? size.width : collapsedSize.width
        let height = model.isExpanded ? size.height : collapsedSize.height
        let cornerRadius: CGFloat = {
            switch model.mode {
            case .compact: return model.isExpanded ? 20 : 12
            case .dashboard: return model.isExpanded ? 22 : 12
            case .wideBar: return 0
            }
        }()
        // Top corners round out to match the bottom when the panel is open.
        let topRadius: CGFloat = model.isExpanded ? cornerRadius : 0

        // The window frame is sized exactly to the panel via NSLayoutConstraint
        // in NotchWindow, so the panel just fills the window — no tricks needed.
        return ZStack(alignment: .top) {
            // Explicit shadow caster — using the exact panel shape guarantees the
            // shadow is never rectangular even when NSViews are composited above.
            NotchPanelShape(bottomRadius: cornerRadius, topRadius: topRadius)
                .fill(Color.black.opacity(0.001))
                .shadow(
                    color: .black.opacity(model.isExpanded ? 0.55 : 0),
                    radius: model.isExpanded ? 28 : 0,
                    x: 0, y: model.isExpanded ? 14 : 0
                )
                .animation(.spring(response: 0.38, dampingFraction: 0.82), value: model.isExpanded)
                .allowsHitTesting(false)

            chrome(cornerRadius: cornerRadius, topRadius: topRadius)
                .contentShape(NotchPanelShape(bottomRadius: cornerRadius, topRadius: topRadius))
                .onTapGesture(perform: onPanelTap)

            ZStack(alignment: .top) {
                HStack(spacing: 6) {
                    ForEach(currentModules, id: \.id) { module in
                        if let collapsed = module.collapsedView() {
                            collapsed
                        }
                    }
                }
                .frame(width: collapsedSize.width, height: collapsedSize.height)
                .opacity(model.isExpanded ? 0 : 1)
                .scaleEffect(model.isExpanded ? 0.92 : 1, anchor: .top)
                .allowsHitTesting(false)

                expandedContent(modules: currentModules, size: size)
                    .opacity(model.isExpanded ? 1 : 0)
                    .scaleEffect(model.isExpanded ? 1 : 0.96, anchor: .top)
                    .allowsHitTesting(model.isExpanded)
            }
            .clipShape(NotchPanelShape(bottomRadius: cornerRadius, topRadius: topRadius))

            if model.isExpanded, model.mode != .wideBar, notchInset > 0 {
                VStack(spacing: 0) {
                    // Cover only the physical notch camera island, not the full panel
                    // width, so the rounded top corners of the expanded panel are visible.
                    Rectangle()
                        .fill(.black)
                        .frame(width: collapsedSize.width, height: notchInset)
                    Spacer(minLength: 0)
                }
                .allowsHitTesting(false)
            }
        }
        .frame(width: width, height: height, alignment: .top)
    }

    @ViewBuilder
    private func expandedContent(modules currentModules: [any NotchModule], size: CGSize) -> some View {
        switch model.mode {
        case .compact:
            compactExpanded(modules: currentModules, size: size)
        case .dashboard:
            DashboardLayoutView(
                modules: currentModules,
                size: size,
                activeMode: model.mode,
                topInset: notchInset,
                onSwitchMode: onSwitchMode,
                isPinned: model.isPinned,
                onTogglePin: onTogglePin,
                onExternalDrop: onExternalDrop
            )
        case .wideBar:
            WideBarLayoutView(
                modules: currentModules,
                size: size,
                onSwitchMode: onSwitchMode
            )
        }
    }

    private func compactExpanded(modules currentModules: [any NotchModule], size: CGSize) -> some View {
        let visible = currentModules.compactMap { module -> (id: String, view: AnyView)? in
            guard let view = module.expandedView() else { return nil }
            return (module.id, view)
        }
        return VStack(spacing: 8) {
            if visible.isEmpty {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: 96)
            } else {
                ForEach(visible, id: \.id) { entry in
                    entry.view
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .dashboardTileSurface()
                }
            }

            // Footer: lock (pin open) on the left, drag handle when pinned, dashboard on the right.
            HStack {
                Button(action: onTogglePin) {
                    Image(systemName: model.isPinned ? "lock.fill" : "lock.open")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(model.isPinned ? Color.white.opacity(0.9) : Color.white.opacity(0.35))
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(model.isPinned ? Color.white.opacity(0.14) : Color.clear)
                        )
                }
                .buttonStyle(.plain)

                if model.isPinned {
                    WindowDragHandleView()
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "grip.horizontal")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.35))
                                .allowsHitTesting(false)
                        )
                }

                Spacer()

                Button(action: onOpenDashboard) {
                    HStack(spacing: 4) {
                        Text("Dashboard")
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color.white.opacity(0.35))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.white.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        // Clear the physical notch so the first card doesn't hide behind it.
        .padding(.top, notchInset + 6)
        .frame(width: size.width, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        // Full-coverage drop zone so files dropped anywhere on the compact panel land in the shelf.
        .dropDestination(for: URL.self) { urls, _ in
            onExternalDrop(urls)
            return true
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: CompactContentHeightKey.self, value: proxy.size.height)
            }
        )
    }

    /// Height of the physical notch, used to inset expanded content so nothing
    /// renders behind the hardware notch.
    /// Physical notch bar height — used to push content below the hardware notch.
    /// Uses safeAreaInsets.top (≈37pt on notched Macs, 0 on non-notched).
    private var notchInset: CGFloat { NSScreen.main?.safeAreaInsets.top ?? 37 }

    private func chrome(cornerRadius: CGFloat, topRadius: CGFloat) -> some View {
        NotchChrome(cornerRadius: cornerRadius, topRadius: topRadius, isExpanded: model.isExpanded, mode: model.mode)
    }
}

/// Glass panel surface shaped like a notch dropdown: real `NSVisualEffectView`
/// blur, a dark tint for legibility over bright desktops, a hairline edge, and a
/// soft drop shadow when expanded. Square top + rounded bottom so it reads as
/// dropping out of the notch rather than floating as a centered card.
struct NotchChrome: View {
    let cornerRadius: CGFloat
    var topRadius: CGFloat = 0
    let isExpanded: Bool
    let mode: ExpansionMode

    var body: some View {
        let shape = NotchPanelShape(bottomRadius: cornerRadius, topRadius: topRadius)
        ZStack {
            // Real glass blur — corner radius applied at the layer level so the
            // blur is actually clipped (SwiftUI clipShape doesn't clip NSViews).
            VisualEffectBackground(
                material: .hudWindow,
                blendingMode: .behindWindow,
                cornerRadius: cornerRadius
            )

            // Deep near-black tint — slightly lighter than before so more of
            // the real blur shows through, reinforcing the glass-slab read.
            LinearGradient(
                colors: [
                    Color.black.opacity(isExpanded ? 0.54 : 0.48),
                    Color.black.opacity(isExpanded ? 0.72 : 0.60)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Ambient notch glow — cool-blue radial bloom from the notch at
            // top-centre. Gives the panel an illuminated, floating quality as
            // if the display hardware is slightly backlit from behind the notch.
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.35, green: 0.55, blue: 0.90)
                            .opacity(isExpanded ? 0.14 : 0), location: 0),
                    .init(color: Color.clear, location: 1)
                ]),
                center: .init(x: 0.5, y: -0.15),
                startRadius: 0,
                endRadius: 480
            )
            .blendMode(.plusLighter)

            // Specular sheen — bright band raked across the top like light
            // catching the curved surface of a glass object.
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(isExpanded ? 0.30 : 0.12), location: 0.0),
                    .init(color: .white.opacity(isExpanded ? 0.10 : 0.04), location: 0.10),
                    .init(color: .white.opacity(0.02), location: 0.25),
                    .init(color: .clear, location: 0.45)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.plusLighter)

            // Inner bottom vignette for depth — panel feels like a solid volume.
            LinearGradient(
                colors: [.clear, .black.opacity(isExpanded ? 0.32 : 0.0)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Crisp rim: bright top edge fading down the sides.
            shape
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(isExpanded ? 0.36 : 0.18),
                            .white.opacity(isExpanded ? 0.08 : 0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
        }
        .clipShape(shape)
        // Shadow is rendered by the caller (panelBody) using an explicit shape
        // so it never falls back to a rectangular silhouette when NSViews are present.
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: isExpanded)
    }
}
