import Foundation
import MacNotchKit

func onboardingStateTests() {
    test("default onboarding is incomplete") {
        expectEqual(OnboardingState.defaults.hasCompletedFirstRun, false, "first run incomplete")
    }

    test("marking onboarding complete is codable") {
        let state = OnboardingState(hasCompletedFirstRun: true, completedVersion: "0.1.0")
        let data = try! JSONEncoder().encode(state)
        let decoded = try! JSONDecoder().decode(OnboardingState.self, from: data)
        expectEqual(decoded.hasCompletedFirstRun, true, "completion persists")
        expectEqual(decoded.completedVersion, "0.1.0", "version persists")
    }

    test("legacy settings without onboarding use defaults") {
        let legacyJSON = """
        {"modules":[{"id":"media","isEnabled":true}],"launchAtLogin":false,"defaultExpansionMode":"dashboard"}
        """
        let decoded = try! JSONDecoder().decode(AppSettings.self, from: Data(legacyJSON.utf8))
        expectEqual(decoded.onboarding, .defaults, "legacy onboarding fallback")
    }
}
