import MacNotchKit

func systemSampleTests() {
    test("battery label shows percent and charging bolt") {
        let sample = SystemSample(
            batteryPercent: 84,
            isCharging: true,
            cpuPercent: 12,
            ramUsedBytes: 0
        )

        expectEqual(sample.batteryLabel, "84% ⚡", "battery label includes charge indicator")
    }

    test("battery label shows dash when battery is unavailable") {
        let sample = SystemSample(
            batteryPercent: nil,
            isCharging: false,
            cpuPercent: 0,
            ramUsedBytes: 0
        )

        expectEqual(sample.batteryLabel, "—", "battery label uses dash when unavailable")
    }

    test("ram label formats decimal gigabytes") {
        let sample = SystemSample(
            batteryPercent: nil,
            isCharging: false,
            cpuPercent: 0,
            ramUsedBytes: 9_300_000_000
        )

        expectEqual(sample.ramLabel, "9.3 GB", "ram label formats one decimal place")
    }

    test("cpu label rounds to nearest integer percent") {
        let sample = SystemSample(
            batteryPercent: nil,
            isCharging: false,
            cpuPercent: 12.6,
            ramUsedBytes: 0
        )

        expectEqual(sample.cpuLabel, "13%", "cpu label rounds to nearest whole percent")
    }

    test("battery percent is unavailable when max capacity is zero") {
        expectEqual(
            SystemSampler.batteryPercent(current: 50, max: 0),
            nil,
            "battery percent stays nil for invalid max capacity"
        )
    }

    test("cpu usage percent uses interval deltas between snapshots") {
        let previous = CPULoadSnapshot(user: 100, system: 50, idle: 200, nice: 25)
        let current = CPULoadSnapshot(user: 145, system: 70, idle: 230, nice: 30)
        let usage = SystemSampler.cpuUsagePercent(previous: previous, current: current)

        expectEqual(usage, 70, "cpu usage is based on busy delta over total delta")
    }

    test("cpu usage percent returns zero for the first snapshot") {
        let current = CPULoadSnapshot(user: 140, system: 70, idle: 220, nice: 30)
        let usage = SystemSampler.cpuUsagePercent(previous: nil, current: current)

        expectEqual(usage, 0, "first cpu snapshot has a safe zero percent fallback")
    }
}
