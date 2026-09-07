import CoreGraphics

public enum NotchWindowInputPolicy {
    public static func shouldCollapseForOutsideClick(
        at screenPoint: CGPoint,
        panelFrame: CGRect,
        state: NotchState,
        phase: NotchWindowTransitionCoordinator.Phase
    ) -> Bool {
        guard !panelFrame.contains(screenPoint) else { return false }

        switch state {
        case .collapsed:
            return false
        case .expanding, .expanded:
            return true
        case .collapsing:
            switch phase {
            case .collapseGrace, .collapseAnimation:
                return true
            case .idle:
                return false
            }
        }
    }
}
