import Foundation

public enum EnergyRefreshPolicy {
    public static func interval(
        base: TimeInterval,
        lowPowerMultiplier: Double,
        isLowPowerModeEnabled: Bool = ProcessInfo.processInfo.isLowPowerModeEnabled
    ) -> TimeInterval {
        guard isLowPowerModeEnabled else { return base }
        return base * max(1, lowPowerMultiplier)
    }

    public static func tolerance(for interval: TimeInterval) -> TimeInterval {
        min(60, max(1, interval * 0.2))
    }
}
