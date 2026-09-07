public enum NotchState {
    case collapsed
    case expanding
    case expanded
    case collapsing
}

/// Which expanded form the notch is showing.
/// Compact = hover preview; dashboard = full tile panel; wideBar = horizontal strip.
public enum ExpansionMode: String, CaseIterable, Codable, Sendable {
    case compact
    case dashboard
    case wideBar
}

public final class NotchStateMachine {
    public private(set) var state: NotchState = .collapsed
    public private(set) var mode: ExpansionMode = .compact
    public var hoverToExpand = true

    /// Which mode a fresh click opens into. Hover always uses `.compact`.
    public var defaultExpandMode: ExpansionMode = .dashboard

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
                mode = .compact
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
        case .collapsed:
            // Fresh click opens into the user's preferred mode (default dashboard).
            mode = defaultExpandMode
            state = .expanding
            return true
        case .collapsing:
            // Toggle-reopen during a pending collapse keeps whatever mode was active
            // (e.g. reopening a hover-driven compact view that started to dismiss).
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
        // Hover-out only collapses the compact preview. Dashboard and wide-bar
        // are click-driven and stay open until an explicit dismiss.
        guard mode == .compact else { return false }
        switch state {
        case .expanded, .expanding:
            state = .collapsing
            return true
        case .collapsed, .collapsing:
            return false
        }
    }

    public func clickedOutside() -> Bool {
        // Outside-click dismisses any expanded mode (used by NotchWindow's click monitors).
        switch state {
        case .expanded, .expanding:
            state = .collapsing
            return true
        case .collapsed, .collapsing:
            return false
        }
    }

    /// Result of a direct click on the notch panel.
    public enum TapOutcome {
        case opening      // was collapsed/collapsing → now expanding into the clicked mode
        case promoting    // was a hover preview → now showing the clicked mode, still expanded
        case collapsing   // a clicked mode was showing → now dismissing
        case noChange
    }

    /// A click directly on the notch/panel. Distinct from hover: a click always
    /// wants the full clicked mode (default dashboard). Hovering only ever shows
    /// `.compact`, so a click on a compact preview *promotes* it to the dashboard
    /// rather than toggling it shut.
    public func tapped() -> TapOutcome {
        switch state {
        case .collapsed:
            mode = defaultExpandMode
            state = .expanding
            return .opening
        case .collapsing:
            mode = defaultExpandMode
            state = .expanding
            return .opening
        case .expanding, .expanded:
            state = .collapsing
            return .collapsing
        }
    }

    /// Switch the active expansion mode without collapsing. Only valid while expanded.
    /// Returns true if the mode actually changed.
    public func switchMode(to newMode: ExpansionMode) -> Bool {
        switch state {
        case .expanding, .expanded:
            guard mode != newMode else { return false }
            mode = newMode
            return true
        case .collapsed, .collapsing:
            return false
        }
    }

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
