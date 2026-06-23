import AppKit
import SwiftUI

@MainActor
final class LauncherModule: NotchModule {
    let id = "launcher"
    let title = "Launcher"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var apps: [PinnedApp] = []
    }

    private let state = StateBox()
    private let store = LauncherStore(url: LauncherStore.defaultURL())

    init() {
        state.apps = store.apps
    }

    func collapsedView() -> AnyView? { nil }
    func expandedView() -> AnyView {
        AnyView(LauncherDashboardTile(
            state: state,
            onLaunch: { [weak self] app in self?.launch(app) },
            onDrop: { [weak self] urls in self?.pinDropped(urls) },
            onRemove: { [weak self] app in self?.remove(app) }
        ))
    }

    func dashboardTile() -> AnyView? {
        AnyView(LauncherDashboardTile(
            state: state,
            onLaunch: { [weak self] app in self?.launch(app) },
            onDrop: { [weak self] urls in self?.pinDropped(urls) },
            onRemove: { [weak self] app in self?.remove(app) }
        ))
    }

    func wideBarView() -> AnyView? { nil }

    func activate() {
        state.apps = store.apps
    }

    func deactivate() {}
    func refresh() async {}

    private func launch(_ app: PinnedApp) {
        let url = URL(fileURLWithPath: app.path)
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in }
    }

    private func pinDropped(_ urls: [URL]) {
        for url in urls {
            let path = url.path
            guard path.hasSuffix(".app") else { continue }
            let bundle = Bundle(url: url)
            let bundleID = bundle?.bundleIdentifier ?? path
            let name = bundle?.infoDictionary?["CFBundleName"] as? String
                ?? url.deletingPathExtension().lastPathComponent
            store.add(path: path, name: name, bundleID: bundleID)
        }
        state.apps = store.apps
    }

    private func remove(_ app: PinnedApp) {
        store.remove(app.bundleID)
        state.apps = store.apps
    }
}
