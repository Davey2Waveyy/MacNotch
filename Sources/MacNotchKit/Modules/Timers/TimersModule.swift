import AppKit
import SwiftUI

@MainActor
final class TimersModule: NotchModule {
    let id = "timers"
    let title = "Timers"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var active: [CountdownTimer] = []
        @Published var now: Date = Date()
        @Published var justFired: String?
    }

    private let state = StateBox()
    private var scheduler = TimerScheduler()
    private var tick: Timer?

    func collapsedView() -> AnyView? {
        AnyView(TimersCollapsedBridge(box: state))
    }

    func expandedView() -> AnyView? { nil }

    func dashboardTile() -> AnyView? {
        AnyView(TimersBridge(
            box: state,
            onStart: { [weak self] minutes, label in self?.start(minutes: minutes, label: label) },
            onCancel: { [weak self] id in self?.cancel(id) }
        ))
    }

    func activate() {
        tick = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.pump() }
        }
        pump()
    }

    func deactivate() {
        tick?.invalidate()
        tick = nil
    }

    func refresh() async { pump() }

    private func start(minutes: Double, label: String) {
        scheduler.add(duration: minutes * 60, label: label, now: Date())
        pump()
    }

    private func cancel(_ id: UUID) {
        scheduler.remove(id: id)
        pump()
    }

    private func pump() {
        let now = Date()
        let fired = scheduler.collectExpired(now: now)
        for timer in fired { fire(timer) }
        state.now = now
        state.active = scheduler.active(now: now)
        if let last = fired.last {
            state.justFired = last.label
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                if self?.state.justFired == last.label { self?.state.justFired = nil }
            }
        }
    }

    private func fire(_ timer: CountdownTimer) {
        NSSound(named: "Glass")?.play()
        // A non-bundled SPM executable can't rely on UNUserNotificationCenter, so
        // we also bounce the Dock-less app's attention via a sound + the inline
        // "fired" banner surfaced in the tile.
        NSApp.requestUserAttention(.criticalRequest)
    }
}

private struct TimersBridge: View {
    @ObservedObject var box: TimersModule.StateBox
    let onStart: (Double, String) -> Void
    let onCancel: (UUID) -> Void

    var body: some View {
        TimersDashboardTile(active: box.active, now: box.now, justFired: box.justFired,
                            onStart: onStart, onCancel: onCancel)
    }
}

private struct TimersCollapsedBridge: View {
    @ObservedObject var box: TimersModule.StateBox
    var body: some View {
        if let next = box.active.first {
            Text(TimerFormat.clock(next.remaining(at: box.now)))
                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}
