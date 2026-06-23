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
    private static let maxCompactHeight: CGFloat = 460
    private let dashboardSize = CGSize(width: 860, height: 260)
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
        let size = expandedSize
        ZStack(alignment: .top) {
            panelBody
        }
        .frame(
            width: model.isExpanded ? size.width : collapsedSize.width,
            height: model.isExpanded ? size.height : collapsedSize.height,
            alignment: .top
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: model.isExpanded)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: model.mode)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: model.compactContentHeight)
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
            chrome(cornerRadius: cornerRadius)
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .onTapGesture(perform: onPanelTap)

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

            expandedContent(modules: currentModules, size: size)
                .opacity(model.isExpanded ? 1 : 0)
                .scaleEffect(model.isExpanded ? 1 : 0.96, anchor: .top)
        }
        .frame(width: width, height: height, alignment: .top)
        .background(chrome(cornerRadius: cornerRadius))
        .clipped()
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
        .padding(12)
        .frame(width: size.width, alignment: .top)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: CompactContentHeightKey.self, value: proxy.size.height)
            }
        )
    }

    private func chrome(cornerRadius: CGFloat) -> some View {
        NotchChrome(cornerRadius: cornerRadius, isExpanded: model.isExpanded, mode: model.mode)
    }
}

/// Layered "glass over black" panel surface: a near-black gradient with a
/// hairline top highlight, an inner stroke, and a soft drop shadow when
/// expanded. Replaces the flat `.black` fill so the panel reads with depth.
struct NotchChrome: View {
    let cornerRadius: CGFloat
    let isExpanded: Bool
    let mode: ExpansionMode

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.07, green: 0.07, blue: 0.08),
                            Color(red: 0.02, green: 0.02, blue: 0.025)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            shape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(isExpanded ? 0.14 : 0.06),
                            .white.opacity(0.015)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.6
                )
        }
        .shadow(color: .black.opacity(isExpanded ? 0.55 : 0), radius: isExpanded ? 18 : 0, x: 0, y: isExpanded ? 8 : 0)
        .animation(.easeOut(duration: 0.25), value: isExpanded)
    }
}
