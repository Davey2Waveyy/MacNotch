import Foundation
import MacNotchKit

func screenTimeTrackerTests() {
    let cal = Calendar(identifier: .gregorian)
    let base = Date(timeIntervalSince1970: 1_700_000_000) // fixed reference

    test("focus accumulates elapsed time into the active app") {
        var t = ScreenTimeTracker(now: base, calendar: cal)
        t.focus(bundleID: "a", name: "Alpha", at: base, calendar: cal)
        t.focus(bundleID: "b", name: "Beta", at: base.addingTimeInterval(60), calendar: cal)
        // 60s should have rolled into Alpha.
        expectEqual(Int(t.usages["a"]?.seconds ?? -1), 60, "alpha gets 60s")
        expectEqual(Int(t.usages["b"]?.seconds ?? -1), 0, "beta starts at 0")
    }

    test("settle folds in-progress time without changing focus") {
        var t = ScreenTimeTracker(now: base, calendar: cal)
        t.focus(bundleID: "a", name: "Alpha", at: base, calendar: cal)
        t.settle(now: base.addingTimeInterval(30), calendar: cal)
        expectEqual(Int(t.totalSeconds), 30, "30s accrued to the active app")
        t.settle(now: base.addingTimeInterval(45), calendar: cal)
        expectEqual(Int(t.totalSeconds), 45, "settle is cumulative, not double-counted")
    }

    test("ranked sorts apps by descending time") {
        var t = ScreenTimeTracker(now: base, calendar: cal)
        t.focus(bundleID: "a", name: "Alpha", at: base, calendar: cal)
        t.focus(bundleID: "b", name: "Beta", at: base.addingTimeInterval(10), calendar: cal) // a:10
        t.focus(bundleID: "a", name: "Alpha", at: base.addingTimeInterval(40), calendar: cal) // b:30
        t.settle(now: base.addingTimeInterval(55), calendar: cal)                              // a:+15 = 25
        let ranked = t.ranked
        expectEqual(ranked.first?.bundleID, "b", "beta (30s) ranks first")
        expectEqual(ranked.count, 2, "two apps tracked")
    }

    test("crossing midnight resets the day") {
        var t = ScreenTimeTracker(now: base, calendar: cal)
        t.focus(bundleID: "a", name: "Alpha", at: base, calendar: cal)
        t.settle(now: base.addingTimeInterval(120), calendar: cal)
        expect(t.totalSeconds > 0, "time accrued before midnight")

        let nextDay = cal.date(byAdding: .day, value: 1, to: base)!
        t.settle(now: nextDay, calendar: cal)
        expectEqual(Int(t.totalSeconds), 0, "totals reset after the day rolls over")
    }

    test("duration formats hours, minutes, seconds") {
        expectEqual(ScreenTimeFormat.duration(4380), "1h 13m", "1h 13m")
        expectEqual(ScreenTimeFormat.duration(2820), "47m", "47m")
        expectEqual(ScreenTimeFormat.duration(38), "38s", "38s")
    }
}
