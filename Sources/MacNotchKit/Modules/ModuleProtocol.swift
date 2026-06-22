import SwiftUI

@MainActor
public protocol NotchModule: AnyObject {
    var id: String { get }
    var title: String { get }
    var isEnabled: Bool { get set }

    func collapsedView() -> AnyView?
    func expandedView() -> AnyView
    func activate()
    func deactivate()
    func refresh() async

    /// Optional dashboard tile rendered in the side-by-side dashboard layout.
    /// Return nil to opt out (default).
    func dashboardTile() -> AnyView?

    /// Optional inline view for the wide-bar mode (status-strip across the top).
    /// Return nil to opt out (default).
    func wideBarView() -> AnyView?
}

public extension NotchModule {
    func dashboardTile() -> AnyView? { nil }
    func wideBarView() -> AnyView? { nil }
}
