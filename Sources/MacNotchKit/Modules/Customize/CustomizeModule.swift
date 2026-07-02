import SwiftUI

@MainActor
public final class CustomizeModule: NotchModule {
    public let id = "customize"
    public let title = "Customize"
    public var isEnabled = true

    public final class SettingsProxy: ObservableObject {
        @Published public var settings: AppSettings
        let titles: [String: String]
        var onChange: (AppSettings) -> Void

        public init(_ settings: AppSettings, titles: [String: String],
             onChange: @escaping (AppSettings) -> Void) {
            self.settings = settings
            self.titles = titles
            self.onChange = onChange
        }

        /// Mutates a copy of `settings`, publishes it, then notifies `onChange`
        /// so callers (module toggles, presets, accent swatches, launch/mode
        /// controls) all go through one path instead of hand-rolling the
        /// read-mutate-publish-notify dance at each call site.
        public func update(_ mutate: (inout AppSettings) -> Void) {
            var next = settings
            mutate(&next)
            settings = next
            onChange(next)
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
