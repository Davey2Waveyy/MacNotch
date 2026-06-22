import Foundation
import MacNotchKit

func calendarFormatTests() {
    var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    func at(_ hour: Int, _ minute: Int) -> Date {
        utc.date(from: DateComponents(year: 2026, month: 6, day: 22, hour: hour, minute: minute))!
    }

    test("calendar: upcoming filters past events and limits count") {
        let now = at(12, 0)
        let events = [
            CalEvent(title: "past", start: at(9, 0), colorHex: nil),
            CalEvent(title: "soon", start: at(13, 0), colorHex: nil),
            CalEvent(title: "later", start: at(16, 0), colorHex: nil),
            CalEvent(title: "evening", start: at(19, 0), colorHex: nil),
        ]
        let upcoming = CalendarFormat.upcoming(events, now: now, limit: 2)
        expect(upcoming.map(\.title) == ["soon", "later"], "future-only, soonest-first, capped at 2")
    }

    test("calendar: upcoming sorts unordered input") {
        let now = at(8, 0)
        let events = [
            CalEvent(title: "b", start: at(16, 0), colorHex: nil),
            CalEvent(title: "a", start: at(10, 0), colorHex: nil),
        ]
        expect(CalendarFormat.upcoming(events, now: now, limit: 5).map(\.title) == ["a", "b"], "sorted by start")
    }

    test("calendar: time label is zero-padded 24-hour") {
        expect(CalendarFormat.timeLabel(at(9, 5), calendar: utc) == "09:05", "morning padded")
        expect(CalendarFormat.timeLabel(at(13, 30), calendar: utc) == "13:30", "afternoon 24h")
    }

    test("calendar: day header is weekday and month/day") {
        expect(CalendarFormat.dayHeader(at(9, 0), calendar: utc) == "Mon, Jun 22", "header format")
    }
}
