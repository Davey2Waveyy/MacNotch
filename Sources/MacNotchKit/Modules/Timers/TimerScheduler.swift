import Foundation

/// A single running countdown.
public struct CountdownTimer: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var label: String
    public var duration: TimeInterval
    public var endDate: Date

    public init(id: UUID = UUID(), label: String, duration: TimeInterval, endDate: Date) {
        self.id = id
        self.label = label
        self.duration = duration
        self.endDate = endDate
    }

    public func remaining(at now: Date) -> TimeInterval {
        max(0, endDate.timeIntervalSince(now))
    }

    public func isExpired(at now: Date) -> Bool {
        now >= endDate
    }

    /// Fraction elapsed in [0, 1].
    public func progress(at now: Date) -> Double {
        guard duration > 0 else { return 1 }
        return min(1, max(0, (duration - remaining(at: now)) / duration))
    }
}

/// Pure, testable store of running countdowns. The module drives it with a 1s
/// tick and injected `Date`s so the timing logic can be tested headlessly.
public struct TimerScheduler: Equatable, Sendable {
    public private(set) var timers: [CountdownTimer]

    public init(timers: [CountdownTimer] = []) {
        self.timers = timers
    }

    @discardableResult
    public mutating func add(duration: TimeInterval, label: String, now: Date) -> CountdownTimer {
        let timer = CountdownTimer(label: label, duration: duration, endDate: now.addingTimeInterval(duration))
        timers.append(timer)
        return timer
    }

    public mutating func remove(id: UUID) {
        timers.removeAll { $0.id == id }
    }

    /// Removes and returns any timers that have expired as of `now`.
    public mutating func collectExpired(now: Date) -> [CountdownTimer] {
        let fired = timers.filter { $0.isExpired(at: now) }
        timers.removeAll { $0.isExpired(at: now) }
        return fired
    }

    /// Running timers, soonest-to-fire first.
    public func active(now: Date) -> [CountdownTimer] {
        timers
            .filter { !$0.isExpired(at: now) }
            .sorted { $0.endDate < $1.endDate }
    }
}

public enum TimerFormat {
    /// Countdown like "24:59" or "1:05:00".
    public static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.up))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}
