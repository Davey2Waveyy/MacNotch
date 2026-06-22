import Foundation

public enum NotchState { case collapsed, expanded }

public final class NotchStateMachine {
    public private(set) var state: NotchState = .collapsed
    public var hoverToExpand = true

    public init() {}

    /// Returns true if `state` changed.
    public func hoverChanged(_ inside: Bool) -> Bool {
        if inside {
            guard hoverToExpand, state == .collapsed else { return false }
            state = .expanded; return true
        } else {
            return mouseExitedPanel()
        }
    }

    public func clicked() -> Bool {
        state = (state == .collapsed) ? .expanded : .collapsed
        return true
    }

    public func mouseExitedPanel() -> Bool {
        guard state == .expanded else { return false }
        state = .collapsed; return true
    }

    public func clickedOutside() -> Bool { mouseExitedPanel() }
}
