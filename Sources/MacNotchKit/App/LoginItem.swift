import Foundation
import ServiceManagement

/// Launch-at-login backed by `SMAppService.mainApp`.
public enum LoginItem {
    public static func isEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    public static func setEnabled(_ on: Bool) {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("MacNotch: login item update failed: \(error.localizedDescription)")
        }
    }
}
