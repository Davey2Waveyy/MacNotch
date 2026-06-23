import SwiftUI

@MainActor
final class RemindersModule: NotchModule {
    let id = "reminders"
    let title = "Reminders"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var reminders: [Reminder] = []
    }

    private let state = StateBox()
    private let store: RemindersStore

    init() {
        self.store = RemindersStore(url: RemindersStore.defaultURL())
        state.reminders = store.reminders
    }

    func collapsedView() -> AnyView? {
        AnyView(RemindersCollapsedBridge(box: state))
    }

    func expandedView() -> AnyView? { nil }

    func dashboardTile() -> AnyView? {
        AnyView(RemindersDashboardBridge(
            box: state,
            onAdd: { [weak self] title in self?.add(title) },
            onToggle: { [weak self] id in self?.toggle(id: id) },
            onRemove: { [weak self] id in self?.remove(id: id) },
            onClearDone: { [weak self] in self?.clearDone() }
        ))
    }

    func wideBarView() -> AnyView? {
        AnyView(RemindersWideBarBridge(box: state))
    }

    func activate() { state.reminders = store.reminders }
    func deactivate() {}
    func refresh() async { state.reminders = store.reminders }

    // MARK: - Private

    private func add(_ title: String) {
        store.add(title)
        state.reminders = store.reminders
    }

    private func toggle(id: UUID) {
        store.toggle(id: id)
        state.reminders = store.reminders
    }

    private func remove(id: UUID) {
        store.remove(id: id)
        state.reminders = store.reminders
    }

    private func clearDone() {
        store.clearDone()
        state.reminders = store.reminders
    }
}

private struct RemindersCollapsedBridge: View {
    @ObservedObject var box: RemindersModule.StateBox
    var body: some View {
        let active = box.reminders.filter { !$0.isDone }
        if !active.isEmpty {
            HStack(spacing: 3) {
                Image(systemName: "checklist")
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(active.count)")
                    .font(.system(size: 9, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

private struct RemindersDashboardBridge: View {
    @ObservedObject var box: RemindersModule.StateBox
    let onAdd: (String) -> Void
    let onToggle: (UUID) -> Void
    let onRemove: (UUID) -> Void
    let onClearDone: () -> Void

    var body: some View {
        RemindersDashboardTile(reminders: box.reminders,
                               onAdd: onAdd, onToggle: onToggle,
                               onRemove: onRemove, onClearDone: onClearDone)
    }
}

private struct RemindersWideBarBridge: View {
    @ObservedObject var box: RemindersModule.StateBox
    var body: some View {
        let count = box.reminders.filter { !$0.isDone }.count
        WideBarItem(systemImage: "checklist", text: count == 0 ? "Done" : "\(count) left")
    }
}
