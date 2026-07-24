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
    /// Current dashboard page. Lives on the model (not view @State) so the
    /// debug/capture hook and future shortcuts can drive page changes.
    @Published public var dashboardPage = 0
    /// User's appearance settings, synced from `SettingsStore` on load/reload.
    @Published public var appearance = NotchAppearance.defaults
    /// Application-wide settings for quick access by modules.
    @Published public var settings = AppSettings.defaults

    public init() {}
}

public struct NotchRootView: View {
    @ObservedObject private var model: NotchWindowModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            .environment(\.notchTokens, themeTokens)
            .environmentObject(model)
            .animation(themeTokens.panelAnimation, value: model.isExpanded)
            .animation(themeTokens.panelAnimation, value: model.mode)
            .animation(themeTokens.panelAnimation, value: model.compactContentHeight)
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
                // Two-layer shadow: a tight contact shadow grounds the panel,
                // a wide ambient one lifts it off the desktop.
                .shadow(
                    color: .black.opacity(model.isExpanded ? 0.38 : 0),
                    radius: model.isExpanded ? 10 : 0,
                    x: 0, y: model.isExpanded ? 5 : 0
                )
                .shadow(
                    color: .black.opacity(model.isExpanded ? 0.42 : 0),
                    radius: model.isExpanded ? 38 : 0,
                    x: 0, y: model.isExpanded ? 20 : 0
                )
                .animation(themeTokens.panelAnimation, value: model.isExpanded)
                .allowsHitTesting(false)

            chrome(cornerRadius: cornerRadius, topRadius: topRadius)
                .contentShape(NotchPanelShape(bottomRadius: cornerRadius, topRadius: topRadius))
                .onTapGesture(perform: onPanelTap)

            // Preset background wash (e.g. Aurora's accent tint); clear for
            // presets that don't define one, so this is a no-op visually.
            NotchPanelShape(bottomRadius: cornerRadius, topRadius: topRadius)
                .fill(themeTokens.backgroundTint)
                .allowsHitTesting(false)

            // Content choreography: the collapsed strip blurs and recedes as the
            // expanded content settles in slightly after the panel frame — the
            // panel reads as revealing its contents rather than swapping them.
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
                .scaleEffect(model.isExpanded ? 0.90 : 1, anchor: .top)
                .blur(radius: contentBlurEnabled && model.isExpanded ? 6 : 0)
                .allowsHitTesting(false)

                expandedContent(modules: currentModules, size: size)
                    .opacity(model.isExpanded ? 1 : 0)
                    .scaleEffect(model.isExpanded ? 1 : 0.96, anchor: .top)
                    .blur(radius: contentBlurEnabled && !model.isExpanded ? 8 : 0)
                    .allowsHitTesting(model.isExpanded)
            }
            .animation(themeTokens.contentAnimation, value: model.isExpanded)
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

            // Footer: pin on the left, explicit drag handle beside it, dashboard on the right.
            HStack(spacing: 2) {
                NotchIconButton(
                    systemName: model.isPinned ? "pin.fill" : "pin",
                    accessibilityLabel: model.isPinned ? "Unpin notch panel" : "Pin notch panel",
                    iconSize: 10,
                    isActive: model.isPinned,
                    action: onTogglePin
                )

                WindowDragHandleView()
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "grip.horizontal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(themeTokens.textQuaternary)
                            .allowsHitTesting(false)
                    )
                    .help("Drag panel")

                Spacer()

                Button(action: onOpenDashboard) {
                    HStack(spacing: 4) {
                        Text("Dashboard")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                    }
                }
                .buttonStyle(.notchGhost)
                .accessibilityLabel("Open dashboard")
                .help("Open dashboard")
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        // Clear the physical notch so the first card doesn't hide behind it.
        .padding(.top, notchInset + 6)
        .frame(width: size.width, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        // Full-coverage drop zone so files dropped anywhere on the compact panel land in the shelf.
        .urlDropTarget(onExternalDrop)
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

    /// Cross-blur between collapsed and expanded content, skipped under
    /// Reduce Motion (the blur is decorative, not informational).
    private var contentBlurEnabled: Bool { themeTokens.motionStyle != .reduced }

    /// Resolved theme tokens for the current appearance settings, re-derived
    /// whenever appearance changes or the system reduced-motion setting flips.
    private var themeTokens: NotchThemeTokens {
        NotchTheme.tokens(for: model.appearance, reduceMotion: reduceMotion)
    }

    private func chrome(cornerRadius: CGFloat, topRadius: CGFloat) -> some View {
        NotchChrome(cornerRadius: cornerRadius, topRadius: topRadius, isExpanded: model.isExpanded, mode: model.mode)
    }
}

/// Glass panel surface shaped like a notch dropdown: real `NSVisualEffectView`
/// blur, a dark tint for legibility over bright desktops, a hairline edge, and a
/// soft drop shadow when expanded. Square top + rounded bottom so it reads as
/// dropping out of the notch rather than floating as a centered card.
struct NotchChrome: View {
    @Environment(\.notchTokens) private var tokens
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

            // Deep near-black tint. Expanded: light enough that the real blur
            // shows through (glass-slab read). Collapsed: near-opaque black so
            // the resting panel blends into the hardware notch instead of
            // reading as a gray tab over bright desktops.
            LinearGradient(
                colors: [
                    Color.black.opacity(isExpanded ? 0.54 : 0.93),
                    Color.black.opacity(isExpanded ? 0.72 : 0.97)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Ambient notch glow — radial bloom from the notch at top-centre in
            // the user's accent, as if the display hardware is slightly backlit
            // from behind the notch. Follows the appearance preset.
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: tokens.accent.opacity(isExpanded ? 0.11 : 0), location: 0),
                    .init(color: Color.clear, location: 1)
                ]),
                center: .init(x: 0.5, y: -0.15),
                startRadius: 0,
                endRadius: 480
            )
            .blendMode(.plusLighter)

            // Specular sheen — soft band raked across the top like light
            // catching the curved surface of a glass object. Nearly off when
            // collapsed so the resting notch stays hardware-black.
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(isExpanded ? 0.22 : 0.04), location: 0.0),
                    .init(color: .white.opacity(isExpanded ? 0.08 : 0.015), location: 0.10),
                    .init(color: .white.opacity(isExpanded ? 0.02 : 0), location: 0.25),
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

            // Crisp rim: bright top edge fading down the sides. Subdued when
            // collapsed — the resting notch shouldn't catch the eye.
            shape
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(isExpanded ? 0.36 : 0.10),
                            .white.opacity(isExpanded ? 0.08 : 0.01)
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
        .animation(tokens.panelAnimation, value: isExpanded)
    }
}
