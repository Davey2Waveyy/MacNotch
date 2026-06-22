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
}
