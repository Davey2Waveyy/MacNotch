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
}
