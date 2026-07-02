import Foundation
import MacNotchKit

func customizeModuleTests() {
    test("SettingsProxy.update mutates, publishes, and notifies onChange") {
        MainActor.assumeIsolated {
            var notified: AppSettings?
            let proxy = CustomizeModule.SettingsProxy(
                .defaults, titles: [:],
                onChange: { notified = $0 }
            )

            proxy.update { $0.appearance.preset = .terminal }

            expectEqual(proxy.settings.appearance.preset, .terminal, "published settings updated")
            expectEqual(notified?.appearance.preset, .terminal, "onChange received the mutated copy")
        }
    }

    test("SettingsProxy.update supports accent color changes") {
        MainActor.assumeIsolated {
            let proxy = CustomizeModule.SettingsProxy(.defaults, titles: [:], onChange: { _ in })

            proxy.update { $0.appearance.accentColor = .amber }

            expectEqual(proxy.settings.appearance.accentColor, .amber, "accent color updated")
        }
    }
}
