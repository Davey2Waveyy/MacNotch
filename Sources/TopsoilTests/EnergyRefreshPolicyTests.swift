import Foundation
import TopsoilKit

func energyRefreshPolicyTests() {
    test("energy refresh policy keeps the base interval outside low power mode") {
        let interval = EnergyRefreshPolicy.interval(
            base: 30,
            lowPowerMultiplier: 4,
            isLowPowerModeEnabled: false
        )

        expectEqual(interval, 30, "normal power uses the base cadence")
    }

    test("energy refresh policy backs off recurring work in low power mode") {
        let interval = EnergyRefreshPolicy.interval(
            base: 30,
            lowPowerMultiplier: 4,
            isLowPowerModeEnabled: true
        )

        expectEqual(interval, 120, "low power stretches the cadence")
    }

    test("energy refresh policy gives timers a bounded coalescing tolerance") {
        expectEqual(EnergyRefreshPolicy.tolerance(for: 5), 1, "short timers get a small tolerance")
        expectEqual(EnergyRefreshPolicy.tolerance(for: 60), 12, "normal timers can coalesce")
        expectEqual(EnergyRefreshPolicy.tolerance(for: 600), 60, "long timers cap tolerance")
    }
}
