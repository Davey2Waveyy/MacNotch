import Foundation

/// A calendar event reduced to what the notch needs to display.
public struct CalEvent: Equatable, Sendable {
    public var title: String
    public var start: Date
    public var colorHex: String?

    public init(title: String, start: Date, colorHex: String?) {
        self.title = title
        self.start = start
        self.colorHex = colorHex
    }
}

/// Pure formatting/filtering for calendar events (no EventKit, so it's testable).
public enum CalendarFormat {
    /// 24-hour zero-padded time, e.g. "09:05".
    public static func timeLabel(_ date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", comps.hour ?? 0, comps.minute ?? 0)
    }

    /// Day header, e.g. "Mon, Jun 22".
    public static func dayHeader(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    /// Events at or after `now`, soonest first, capped at `limit`.
    public static func upcoming(_ events: [CalEvent], now: Date, limit: Int) -> [CalEvent] {
        events
            .filter { $0.start >= now }
            .sorted { $0.start < $1.start }
            .prefix(limit)
            .map { $0 }
    }
}
