import SwiftUI

@MainActor
final class PomodoroModule: NotchModule {
    let id = "pomodoro"
    let title = "Pomodoro"
    var isEnabled = true

    private let store = PomodoroStore()

    func collapsedView() -> AnyView? {
        AnyView(PomodoroCollapsedView(store: store))
    }

    func expandedView() -> AnyView? {
        AnyView(PomodoroExpandedView(store: store))
    }

    func dashboardTile() -> AnyView? {
        AnyView(PomodoroDashboardTile(store: store))
    }

    func activate() {}
    func deactivate() { store.pause() }
    func refresh() async {}
}
