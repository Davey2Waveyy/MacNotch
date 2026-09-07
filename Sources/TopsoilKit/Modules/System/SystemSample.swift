import Foundation

public struct SystemSample: Sendable {
    public var batteryPercent: Int?
    public var isCharging: Bool
    public var cpuPercent: Double
    public var ramUsedBytes: UInt64

    public init(
        batteryPercent: Int?,
        isCharging: Bool,
        cpuPercent: Double,
        ramUsedBytes: UInt64
    ) {
        self.batteryPercent = batteryPercent
        self.isCharging = isCharging
        self.cpuPercent = cpuPercent
        self.ramUsedBytes = ramUsedBytes
    }
}

public extension SystemSample {
    var batteryLabel: String {
        guard let batteryPercent else { return "—" }
        return isCharging ? "\(batteryPercent)% ⚡" : "\(batteryPercent)%"
    }

    var ramLabel: String {
        let gigabytes = Double(ramUsedBytes) / 1_000_000_000
        return String(format: "%.1f GB", gigabytes)
    }

    var cpuLabel: String {
        "\(Int(cpuPercent.rounded()))%"
    }
}
