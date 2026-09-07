import AppKit
import EventKit
import SwiftUI

@MainActor
final class CalendarModule: NotchModule {
    let id = "calendar"
    let title = "Calendar"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var events: [CalEvent] = []
        @Published var accessDenied = false
    }

    private let state = StateBox()
    private let store = EKEventStore()
    private let refreshCoordinator = CalendarRefreshCoordinator()

    func collapsedView() -> AnyView? {
        nil
    }

    func expandedView() -> AnyView? {
        AnyView(CalendarBridge(box: state, onGrantAccess: openCalendarSettings))
    }

    func dashboardTile() -> AnyView? {
        AnyView(CalendarDashboardBridge(box: state, onGrantAccess: openCalendarSettings))
    }

    func wideBarView() -> AnyView? {
        AnyView(CalendarWideBarBridge(box: state))
    }

    func activate() {
        refreshCoordinator.activate { [weak self] in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
        Task { @MainActor in await refresh() }
    }

    func deactivate() {
        refreshCoordinator.deactivate()
    }

    func refresh() async {
        let granted = (try? await store.requestFullAccessToEvents()) ?? false
        guard granted else {
            state.accessDenied = true
            return
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let mapped = store.events(matching: predicate).map { event in
            CalEvent(title: event.title ?? "Untitled",
                     start: event.startDate ?? start,
                     colorHex: nil)
        }

        state.accessDenied = false
        state.events = CalendarFormat.upcoming(mapped, now: Date(), limit: 4)
    }
    private func openCalendarSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

private struct CalendarBridge: View {
    @ObservedObject var box: CalendarModule.StateBox
    let onGrantAccess: () -> Void

    var body: some View {
        CalendarExpandedView(events: box.events,
                             accessDenied: box.accessDenied,
                             onGrantAccess: onGrantAccess)
    }
}

private struct CalendarDashboardBridge: View {
    @ObservedObject var box: CalendarModule.StateBox
    let onGrantAccess: () -> Void

    var body: some View {
        CalendarDashboardTile(events: box.events,
                              accessDenied: box.accessDenied,
                              onGrantAccess: onGrantAccess)
    }
}

private struct CalendarWideBarBridge: View {
    @ObservedObject var box: CalendarModule.StateBox

    var body: some View {
        CalendarWideBar(events: box.events, accessDenied: box.accessDenied)
    }
}
