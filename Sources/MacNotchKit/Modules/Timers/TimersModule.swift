import AppKit
import SwiftUI

public extension Notification.Name {
    /// Posted when a countdown reaches zero so the notch can pop open and alarm.
    static let macNotchTimerFired = Notification.Name("macNotchTimerFired")
}

@MainActor
final class TimersModule: NotchModule {
    let id = "timers"
    let title = "Timers"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var active: [CountdownTimer] = []
        @Published var firing: [CountdownTimer] = []
        @Published var now: Date = Date()
    }

    private let state = StateBox()
    private var scheduler = TimerScheduler()
    private var scheduledTick: Timer?
    private var alarm: NSSound?

    func collapsedView() -> AnyView? {
        AnyView(TimersCollapsedBridge(box: state))
    }

    func expandedView() -> AnyView? { nil }

    func dashboardTile() -> AnyView? {
        AnyView(TimersBridge(
            box: state,
            onStart: { [weak self] minutes, label in self?.start(minutes: minutes, label: label) },
            onCancel: { [weak self] id in self?.cancel(id) },
            onDismiss: { [weak self] id in self?.dismiss(id) }
        ))
    }

    func activate() {
        pump()
    }

    func deactivate() {
        scheduledTick?.invalidate()
        scheduledTick = nil
        stopAlarm()
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

    private func dismiss(_ id: UUID) {
        state.firing.removeAll { $0.id == id }
        stopAlarm()
    }

    private func pump() {
        scheduledTick?.invalidate()
        scheduledTick = nil

        let now = Date()
        let fired = scheduler.collectExpired(now: now)
        if !fired.isEmpty {
            state.firing.append(contentsOf: fired)
            startAlarm()
            NotificationCenter.default.post(name: .macNotchTimerFired, object: nil)
            NSApp.requestUserAttention(.criticalRequest)
        }

        let active = scheduler.active(now: now)
        if !active.isEmpty {
            state.now = now
        }
        state.active = active
        scheduleNextTick(active: active, now: now)
    }

    private func scheduleNextTick(active: [CountdownTimer], now: Date) {
        guard let nextWake = TimerRefreshPolicy.nextWakeDate(active: active, now: now) else { return }
        let timer = Timer(fire: nextWake, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in self?.pump() }
        }
        timer.tolerance = min(0.1, max(0, nextWake.timeIntervalSince(now) * 0.2))
        scheduledTick = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func startAlarm() {
        guard alarm == nil else { return }
        let sound = NSSound(named: "Glass") ?? NSSound(named: "Ping")
        sound?.loops = true
        sound?.play()
        alarm = sound
    }

    private func stopAlarm() {
        alarm?.stop()
        alarm = nil
    }
}

private struct TimersBridge: View {
    @ObservedObject var box: TimersModule.StateBox
    let onStart: (Double, String) -> Void
    let onCancel: (UUID) -> Void
    let onDismiss: (UUID) -> Void

    var body: some View {
        TimersDashboardTile(active: box.active, now: box.now, firing: box.firing,
                            onStart: onStart, onCancel: onCancel, onDismiss: onDismiss)
    }
}

private struct TimersCollapsedBridge: View {
    @ObservedObject var box: TimersModule.StateBox
    var body: some View {
        if !box.firing.isEmpty {
            Image(systemName: "bell.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color(red: 0.36, green: 0.78, blue: 1))
                .modifier(PulseEffect())
        } else if let next = box.active.first {
            Text(TimerFormat.clock(next.remaining(at: box.now)))
                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}
