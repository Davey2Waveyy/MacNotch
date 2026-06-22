import Combine
import SwiftUI

@MainActor
public final class NotchWindowModel: ObservableObject {
    @Published public var isExpanded = false

    public init() {}
}

public struct NotchRootView: View {
    @ObservedObject private var model: NotchWindowModel
    private let expandedWidth: CGFloat
    private let expandedHeight: CGFloat
    private let collapsedSize: CGSize
    private let modules: () -> [any NotchModule]

    public init(
        model: NotchWindowModel,
        expandedWidth: CGFloat,
        expandedHeight: CGFloat,
        collapsedSize: CGSize,
        modules: @escaping () -> [any NotchModule]
    ) {
        self.model = model
        self.expandedWidth = expandedWidth
        self.expandedHeight = expandedHeight
        self.collapsedSize = collapsedSize
        self.modules = modules
    }

    public var body: some View {
        ZStack(alignment: .top) {
            panelBody
        }
        .frame(width: expandedWidth, height: expandedHeight, alignment: .top)
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: model.isExpanded)
    }

    @ViewBuilder
    private var panelBody: some View {
        let currentModules = modules()

        if model.isExpanded {
            VStack(spacing: 10) {
                if currentModules.isEmpty {
                    Color.clear
                        .frame(maxWidth: .infinity, minHeight: expandedHeight - 28)
                } else {
                    ForEach(Array(currentModules.enumerated()), id: \.offset) { _, module in
                        module.expandedView()
                    }
                }
            }
            .padding(14)
            .frame(width: expandedWidth, height: expandedHeight, alignment: .top)
            .background(chrome(cornerRadius: 20))
            .transition(.opacity)
        } else {
            HStack(spacing: 6) {
                ForEach(Array(currentModules.enumerated()), id: \.offset) { _, module in
                    if let collapsed = module.collapsedView() {
                        collapsed
                    }
                }
            }
            .frame(width: collapsedSize.width, height: collapsedSize.height)
            .background(chrome(cornerRadius: 12))
            .transition(.opacity)
        }
    }

    private func chrome(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.black)
    }
}
