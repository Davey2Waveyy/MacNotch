public enum NotchState {
    case collapsed
    case expanding
    case expanded
    case collapsing
}

public final class NotchStateMachine {
    public private(set) var state: NotchState = .collapsed
    public var hoverToExpand = true

    public init() {}

    public var isExpanded: Bool {
        switch state {
        case .collapsed, .collapsing:
            return false
        case .expanding, .expanded:
            return true
        }
    }

    /// Returns true if `state` changed.
    public func hoverChanged(_ inside: Bool) -> Bool {
        if inside {
            guard hoverToExpand else { return false }

            switch state {
            case .collapsed, .collapsing:
                state = .expanding
                return true
            case .expanding, .expanded:
                return false
            }
        } else {
            return mouseExitedPanel()
        }
    }

    public func clicked() -> Bool {
        switch state {
        case .collapsed, .collapsing:
            state = .expanding
            return true
        case .expanding, .expanded:
            state = .collapsing
            return true
        }
    }

    /// Requests collapse without reopening if collapse is already pending.
    public func forceCollapse() -> Bool {
        switch state {
        case .collapsed:
            return false
        case .expanding, .expanded:
            state = .collapsing
            return true
        case .collapsing:
            return true
        }
    }

    public func mouseExitedPanel() -> Bool {
        switch state {
        case .expanded, .expanding:
            state = .collapsing
            return true
        case .collapsed, .collapsing:
            return false
        }
    }

    public func clickedOutside() -> Bool { mouseExitedPanel() }

    public func completeExpand() -> Bool {
        guard state == .expanding else { return false }
        state = .expanded
        return true
    }

    public func completeCollapse() -> Bool {
        guard state == .collapsing else { return false }
        state = .collapsed
        return true
    }
}
