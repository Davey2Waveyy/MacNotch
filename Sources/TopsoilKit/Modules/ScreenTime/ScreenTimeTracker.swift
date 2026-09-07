import Foundation

/// One app's accumulated foreground time for the current day.
public struct AppUsage: Codable, Equatable, Identifiable, Sendable {
    public var bundleID: String
    public var name: String
    public var seconds: TimeInterval

    public var id: String { bundleID }

    public init(bundleID: String, name: String, seconds: TimeInterval) {
        self.bundleID = bundleID
        self.name = name
        self.seconds = seconds
    }
}

/// Pure, testable accumulator of per-app foreground time. The module feeds it
/// `focus(...)` events with timestamps; it tracks the active app and rolls the
/// elapsed time into the previously-focused app. Resets when the day changes.
public struct ScreenTimeTracker: Equatable, Sendable {
    public private(set) var usages: [String: AppUsage]
    private var activeBundleID: String?
    private var activeSince: Date?
    private var dayStart: Date

    public init(now: Date = Date(), calendar: Calendar = .current) {
        usages = [:]
        dayStart = calendar.startOfDay(for: now)
    }

    /// Total tracked seconds across all apps today.
    public var totalSeconds: TimeInterval {
        usages.values.reduce(0) { $0 + $1.seconds }
    }

    /// Apps sorted by descending time.
    public var ranked: [AppUsage] {
        usages.values.sorted { $0.seconds > $1.seconds }
    }

    /// Record that `bundleID`/`name` became the foreground app at `at`.
    /// Rolls the elapsed time since the last focus into the previous app.
    public mutating func focus(bundleID: String, name: String, at: Date, calendar: Calendar = .current) {
        rollOverIfNewDay(now: at, calendar: calendar)
        commitElapsed(upTo: at)
        activeBundleID = bundleID
        activeSince = at
        if usages[bundleID] == nil {
            usages[bundleID] = AppUsage(bundleID: bundleID, name: name, seconds: 0)
        } else {
            usages[bundleID]?.name = name
        }
    }

    /// Fold any time elapsed up to `now` into the active app without changing focus.
    /// Call before reading totals so the in-progress session is counted.
    public mutating func settle(now: Date, calendar: Calendar = .current) {
        rollOverIfNewDay(now: now, calendar: calendar)
        commitElapsed(upTo: now)
        activeSince = now
    }

    private mutating func commitElapsed(upTo now: Date) {
        guard let active = activeBundleID, let since = activeSince else { return }
        let elapsed = now.timeIntervalSince(since)
        guard elapsed > 0 else { return }
        usages[active]?.seconds += elapsed
    }

    private mutating func rollOverIfNewDay(now: Date, calendar: Calendar) {
        let today = calendar.startOfDay(for: now)
        guard today != dayStart else { return }
        usages = [:]
        dayStart = today
        // Keep the active app but restart its timer from the day boundary.
        activeSince = now
        if let active = activeBundleID {
            usages[active] = AppUsage(bundleID: active, name: active, seconds: 0)
        }
    }
}
