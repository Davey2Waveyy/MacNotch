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

    public init() {}
}

public struct NotchRootView: View {
    @ObservedObject private var model: NotchWindowModel
    private let collapsedSize: CGSize
    private let modules: () -> [any NotchModule]
    private let onPanelTap: () -> Void
    private let onSwitchMode: (ExpansionMode) -> Void

    private let compactWidth: CGFloat = 280
    private static let minCompactHeight: CGFloat = 132
    private static let maxCompactHeight: CGFloat = 520
    private let dashboardSize = CGSize(width: 900, height: 296)
    private let wideBarHeight: CGFloat = 56

    public init(
        model: NotchWindowModel,
        collapsedSize: CGSize,
        modules: @escaping () -> [any NotchModule],
        onPanelTap: @escaping () -> Void = {},
        onSwitchMode: @escaping (ExpansionMode) -> Void = { _ in }
    ) {
        self.model = model
        self.collapsedSize = collapsedSize
        self.modules = modules
        self.onPanelTap = onPanelTap
        self.onSwitchMode = onSwitchMode
    }

    public var body: some View {
        // Fill the hosting window and pin the panel to the TOP. Without this the
        // panel (which is smaller than the window during the open animation) gets
        // centered by AppKit, so it appears to grow from the middle/bottom instead
        // of dropping down from the notch.
        ZStack(alignment: .top) {
            panelBody
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

        return ZStack(alignment: .top) {
            // Single glass chrome (keeps its own silhouette + shadow, so the
            // shadow is not clipped by the content clip below).
            chrome(cornerRadius: cornerRadius)
                .contentShape(NotchPanelShape(bottomRadius: cornerRadius))
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
                    // The compact preview is a glance: the whole thing taps through
                    // to open the dashboard (where the real controls live). Interactive
                    // modes keep hit-testing so their buttons work.
                    .allowsHitTesting(model.mode != .compact)
            }
            .clipShape(NotchPanelShape(bottomRadius: cornerRadius))
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
                onSwitchMode: onSwitchMode
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
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        // Clear the physical notch so the first card doesn't hide behind it.
        .padding(.top, notchInset + 6)
        .frame(width: size.width, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: CompactContentHeightKey.self, value: proxy.size.height)
            }
        )
    }

    /// Height of the physical notch, used to inset expanded content so nothing
    /// renders behind the hardware notch.
    private var notchInset: CGFloat { collapsedSize.height }

    private func chrome(cornerRadius: CGFloat) -> some View {
        NotchChrome(cornerRadius: cornerRadius, isExpanded: model.isExpanded, mode: model.mode)
    }
}

/// Glass panel surface shaped like a notch dropdown: real `NSVisualEffectView`
/// blur, a dark tint for legibility over bright desktops, a hairline edge, and a
/// soft drop shadow when expanded. Square top + rounded bottom so it reads as
/// dropping out of the notch rather than floating as a centered card.
struct NotchChrome: View {
    let cornerRadius: CGFloat
    let isExpanded: Bool
    let mode: ExpansionMode

    var body: some View {
        let shape = NotchPanelShape(bottomRadius: cornerRadius)
        ZStack {
            // Real glass blur of whatever is behind the panel.
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)

            // Light dark tint: enough for legibility, sheer enough that the blur
            // still reads as glass rather than a flat dark card.
            LinearGradient(
                colors: [
                    Color.black.opacity(isExpanded ? 0.24 : 0.46),
                    Color.black.opacity(isExpanded ? 0.42 : 0.58)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Specular sheen — a soft bright band raked across the top, the way
            // light catches the curved top of a glass object. This is what sells
            // "glass" rather than "frosted panel".
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(isExpanded ? 0.16 : 0.10), location: 0.0),
                    .init(color: .white.opacity(0.03), location: 0.18),
                    .init(color: .clear, location: 0.42)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.plusLighter)

            // Inner bottom shadow for depth, so the panel feels like a solid
            // volume of glass rather than a flat sheet.
            LinearGradient(
                colors: [.clear, .black.opacity(isExpanded ? 0.22 : 0.0)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Crisp rim: bright at the top edge, fading down the sides.
            shape
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(isExpanded ? 0.30 : 0.16),
                            .white.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.8
                )
        }
        .clipShape(shape)
        .shadow(color: .black.opacity(isExpanded ? 0.5 : 0), radius: isExpanded ? 22 : 0, x: 0, y: isExpanded ? 12 : 0)
        .animation(.easeOut(duration: 0.25), value: isExpanded)
    }
}
