import SwiftUI

@MainActor
public final class CustomizeModule: NotchModule {
    public let id = "customize"
    public let title = "Customize"
    public var isEnabled = true

    public final class SettingsProxy: ObservableObject {
        @Published var settings: AppSettings
        let titles: [String: String]
        var onChange: (AppSettings) -> Void

        init(_ settings: AppSettings, titles: [String: String],
             onChange: @escaping (AppSettings) -> Void) {
            self.settings = settings
            self.titles = titles
            self.onChange = onChange
        }
    }

    let proxy: SettingsProxy

    public init(settings: AppSettings, titles: [String: String],
                onChange: @escaping (AppSettings) -> Void) {
        proxy = SettingsProxy(settings, titles: titles, onChange: onChange)
    }

    /// Called by AppDelegate after persisting a settings change so the tile stays in sync.
    public func sync(_ newSettings: AppSettings) {
        proxy.settings = newSettings
    }

    public func collapsedView() -> AnyView? { nil }
    public func expandedView() -> AnyView? { nil }
    public func wideBarView() -> AnyView? { nil }

    public func dashboardTile() -> AnyView? {
        AnyView(CustomizeDashboardTile(proxy: proxy))
    }

    public func activate() {}
    public func deactivate() {}
    public func refresh() async {}
}
