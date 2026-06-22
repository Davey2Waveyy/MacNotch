import Foundation
import ServiceManagement

/// Launch-at-login backed by `SMAppService.mainApp`.
public enum LoginItem {
    public static func isEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    public static func setEnabled(_ on: Bool) -> Bool {
        do {
            if on {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            NSLog("MacNotch: login item update failed: \(error.localizedDescription)")
            return false
        }
    }
}
