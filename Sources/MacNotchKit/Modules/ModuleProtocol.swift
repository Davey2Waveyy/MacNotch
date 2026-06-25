import SwiftUI

@MainActor
public protocol NotchModule: AnyObject {
    var id: String { get }
    var title: String { get }
    var isEnabled: Bool { get set }

    func collapsedView() -> AnyView?
    /// Card rendered in the compact (hover) view. Return nil to opt out of
    /// compact entirely — useful for dashboard-only modules.
    func expandedView() -> AnyView?
    func activate()
    func deactivate()
    func refresh() async

    /// Optional dashboard tile rendered in the side-by-side dashboard layout.
    /// Return nil to opt out (default).
    func dashboardTile() -> AnyView?

    /// When true the tile occupies its own full-width page in the dashboard
    /// rather than sharing a row with up to four other tiles.
    var isFullPageTile: Bool { get }

    /// Optional inline view for the wide-bar mode (status-strip across the top).
    /// Return nil to opt out (default).
    func wideBarView() -> AnyView?
}

public extension NotchModule {
    func dashboardTile() -> AnyView? { nil }
    var isFullPageTile: Bool { false }
    func wideBarView() -> AnyView? { nil }
}
