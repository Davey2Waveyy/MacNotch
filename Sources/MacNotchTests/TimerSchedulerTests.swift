import Foundation
import MacNotchKit

func timerSchedulerTests() {
    let base = Date(timeIntervalSince1970: 1_700_000_000)

    test("add creates a timer ending duration seconds out") {
        var s = TimerScheduler()
        let t = s.add(duration: 300, label: "5m", now: base)
        expectEqual(Int(t.endDate.timeIntervalSince(base)), 300, "ends 300s later")
        expectEqual(s.timers.count, 1, "one timer queued")
    }

    test("remaining counts down and clamps at zero") {
        var s = TimerScheduler()
        let t = s.add(duration: 60, label: "1m", now: base)
        expectEqual(Int(t.remaining(at: base.addingTimeInterval(20))), 40, "40s left after 20s")
        expectEqual(Int(t.remaining(at: base.addingTimeInterval(90))), 0, "clamps at zero past the end")
    }

    test("collectExpired returns and removes only fired timers") {
        var s = TimerScheduler()
        _ = s.add(duration: 60, label: "short", now: base)
        _ = s.add(duration: 600, label: "long", now: base)

        let fired = s.collectExpired(now: base.addingTimeInterval(120))
        expectEqual(fired.count, 1, "one fired")
        expectEqual(fired.first?.label, "short", "the short timer fired")
        expectEqual(s.timers.count, 1, "the long timer remains")
    }

    test("active sorts soonest-to-fire first and excludes expired") {
        var s = TimerScheduler()
        _ = s.add(duration: 600, label: "long", now: base)
        _ = s.add(duration: 120, label: "mid", now: base)
        _ = s.add(duration: 30, label: "done", now: base)

        let active = s.active(now: base.addingTimeInterval(60)) // "done" expired
        expectEqual(active.map(\.label), ["mid", "long"], "sorted by end, expired excluded")
    }

    test("clock formats minutes and hours") {
        expectEqual(TimerFormat.clock(1500), "25:00", "25:00 for a fresh 25m timer")
        expectEqual(TimerFormat.clock(1499.1), "25:00", "fractional seconds round up")
        expectEqual(TimerFormat.clock(65), "1:05", "1:05")
        expectEqual(TimerFormat.clock(3661), "1:01:01", "1:01:01")
    }

    test("progress reports the elapsed fraction") {
        let t = CountdownTimer(label: "x", duration: 100, endDate: base.addingTimeInterval(100))
        expect(abs(t.progress(at: base.addingTimeInterval(25)) - 0.25) < 0.001, "25% elapsed")
        expect(abs(t.progress(at: base.addingTimeInterval(100)) - 1.0) < 0.001, "100% at end")
    }
}
