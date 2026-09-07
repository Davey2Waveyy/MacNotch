import AppKit
import SwiftUI

/// Offscreen snapshot renderer for design iteration: renders the real
/// `NotchRootView` (and the real module registry, unactivated) to PNGs via
/// `ImageRenderer`, composited over a synthetic desktop so the translucent
/// panel is judgeable. NSViewRepresentables (the blur layer, drag handles)
/// don't render offscreen; everything SwiftUI-native does.
@MainActor
public enum NotchSnapshots {
    public static func run(outputDirectory: String) -> Int {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)

        let dir = URL(fileURLWithPath: outputDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let modules = makeModules()
        let collapsedSize = CGSize(width: 200, height: 37)
        var failures = 0

        for state in SnapshotState.all {
            let model = NotchWindowModel()
            model.settings = .defaults
            model.appearance = state.appearance
            model.mode = state.mode
            model.dashboardPage = state.page
            model.isExpanded = state.isExpanded
            model.compactContentHeight = 400

            let root = NotchRootView(
                model: model,
                collapsedSize: collapsedSize,
                modules: { modules }
            )

            let panelSize = state.panelSize(collapsed: collapsedSize, model: model, modules: modules)
            let stage = SnapshotStage(panelSize: panelSize) { root }

            let renderer = ImageRenderer(content: stage)
            renderer.scale = 2

            guard let cgImage = renderer.cgImage else {
                print("✗ \(state.name): render produced no image")
                failures += 1
                continue
            }
            let rep = NSBitmapImageRep(cgImage: cgImage)
            guard let data = rep.representation(using: .png, properties: [:]) else {
                print("✗ \(state.name): PNG encode failed")
                failures += 1
                continue
            }
            let url = dir.appendingPathComponent("\(state.name).png")
            do {
                try data.write(to: url)
                print("✓ \(state.name) → \(url.path)")
            } catch {
                print("✗ \(state.name): \(error)")
                failures += 1
            }
        }
        return failures == 0 ? 0 : 1
    }

    /// Same registry the app builds, with stub callbacks; modules are never
    /// activated so views render their idle/empty states without permission prompts.
    private static func makeModules() -> [any NotchModule] {
        let registry = ModuleRegistry()
        registry.register(QuickTogglesModule())
        registry.register(ScreenTimeModule())
        registry.register(TimersModule())
        registry.register(PomodoroModule())
        registry.register(ShelfModule(store: ShelfStore(url: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("shelf.json"))))
        registry.register(ActionsModule())
        registry.register(MediaModule())
        registry.register(RemindersModule())
        registry.register(CalendarModule())
        registry.register(ClipboardModule())
        registry.register(SystemModule())
        registry.register(LauncherModule())
        registry.register(CodeModule())
        registry.register(CommandPaletteModule(commands: [
            CommandPaletteCommand(id: "open-settings", title: "Open Settings", keywords: ["preferences"]) {},
            CommandPaletteCommand(id: "toggle-notch", title: "Toggle Notch", keywords: ["panel"]) {}
        ]))
        registry.register(StocksModule())
        registry.register(GardenModule())

        let enabledIDs = AppSettings.defaults.modules.filter(\.isEnabled).map(\.id)
        return registry.ordered(by: enabledIDs)
    }
}

private struct SnapshotState {
    let name: String
    let mode: ExpansionMode
    let isExpanded: Bool
    var appearance: NotchAppearance = .defaults
    var page: Int = 0

    @MainActor
    func panelSize(collapsed: CGSize, model: NotchWindowModel, modules: [any NotchModule]) -> CGSize {
        guard isExpanded else { return collapsed }
        switch mode {
        case .compact: return CGSize(width: 280, height: model.compactContentHeight)
        case .dashboard:
            let descriptors = modules.compactMap { module -> DashboardModuleDescriptor? in
                guard module.dashboardTile() != nil else { return nil }
                return DashboardModuleDescriptor(id: module.id, title: module.title, isFullPage: module.isFullPageTile)
            }
            let height = DashboardNavigation.height(modules: descriptors, page: page, layout: appearance.dashboardLayout)
            return CGSize(width: 1120, height: height)
        case .wideBar: return CGSize(width: 1340, height: 44)
        }
    }

    private static func layoutAppearance(_ layout: DashboardLayoutPreference) -> NotchAppearance {
        var appearance = NotchAppearance.defaults
        appearance.dashboardLayout = layout
        return appearance
    }

    static let all: [SnapshotState] = [
        SnapshotState(name: "01-collapsed", mode: .compact, isExpanded: false),
        SnapshotState(name: "02-compact-hover", mode: .compact, isExpanded: true),
        SnapshotState(name: "03-dashboard", mode: .dashboard, isExpanded: true),
        SnapshotState(name: "04-widebar", mode: .wideBar, isExpanded: true),
        SnapshotState(name: "05-code", mode: .dashboard, isExpanded: true, page: 1),
        SnapshotState(name: "06-commands", mode: .dashboard, isExpanded: true, page: 2),
        SnapshotState(name: "07-stocks", mode: .dashboard, isExpanded: true, page: 3),
        SnapshotState(name: "08-priority", mode: .dashboard, isExpanded: true, appearance: layoutAppearance(.priority)),
        SnapshotState(name: "09-focus", mode: .dashboard, isExpanded: true, appearance: layoutAppearance(.fullPageFocus)),
    ]
}

/// Dark synthetic desktop behind the panel so translucent blacks read correctly.
private struct SnapshotStage<Content: View>: View {
    let panelSize: CGSize
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.18, blue: 0.26),
                    Color(red: 0.05, green: 0.05, blue: 0.09)
                ],
                startPoint: .top, endPoint: .bottom
            )
            content()
        }
        .frame(width: panelSize.width + 120, height: panelSize.height + 80, alignment: .top)
        .environment(\.notchSnapshotMode, true)
    }
}
