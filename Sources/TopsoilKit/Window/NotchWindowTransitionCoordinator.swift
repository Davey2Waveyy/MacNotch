public final class NotchWindowTransitionCoordinator {
    public enum Phase: Equatable {
        case idle
        case collapseGrace
        case collapseAnimation
    }

    public private(set) var isVisuallyExpanded = false
    public private(set) var phase: Phase = .idle

    public init() {}

    public func sync(for state: NotchState) {
        switch state {
        case .collapsed:
            isVisuallyExpanded = false
            phase = .idle
        case .expanding, .expanded:
            isVisuallyExpanded = true
            phase = .idle
        case .collapsing:
            switch phase {
            case .idle:
                isVisuallyExpanded = false
                phase = .collapseAnimation
            case .collapseGrace:
                isVisuallyExpanded = true
            case .collapseAnimation:
                isVisuallyExpanded = false
            }
        }
    }

    public func requestGracefulCollapse() {
        phase = .collapseGrace
        isVisuallyExpanded = true
    }

    public func requestImmediateCollapse() {
        phase = .collapseAnimation
        isVisuallyExpanded = false
    }

    @discardableResult
    public func advanceCollapseGrace(for state: NotchState) -> Bool {
        guard state == .collapsing, phase == .collapseGrace else { return false }
        phase = .collapseAnimation
        isVisuallyExpanded = false
        return true
    }

    @discardableResult
    public func advanceCollapseAnimation(for state: NotchState) -> Bool {
        guard state == .collapsing, phase == .collapseAnimation else { return false }
        phase = .idle
        return true
    }
}
