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
    private var timer: Timer?

    func collapsedView() -> AnyView? {
        nil
    }

    func expandedView() -> AnyView {
        AnyView(CalendarBridge(box: state, onGrantAccess: openCalendarSettings))
    }

    func activate() {
        startTimer()
        Task { @MainActor in await refresh() }
    }

    func deactivate() {
        timer?.invalidate()
        timer = nil
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

    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
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
