import SwiftUI

@MainActor
final class CodeModule: NotchModule {
    let id = "code"
    let title = "Code"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var projects: [CodeProjectDisplay] = []
    }

    private let state = StateBox()
    private let store = CodeProjectStore(url: CodeProjectStore.defaultURL())
    private var timer: Timer?

    init() {
        state.projects = store.projects.map { CodeProjectDisplay(name: $0.name, status: .unknown) }
    }

    func collapsedView() -> AnyView? {
        nil
    }

    func expandedView() -> AnyView? {
        AnyView(CodeBridge(
            box: state,
            onAction: { [weak self] index, action in self?.perform(action, at: index) },
            onRemove: { [weak self] index in self?.remove(at: index) },
            onDrop: { [weak self] urls in self?.pin(urls) }
        ))
    }

    func dashboardTile() -> AnyView? {
        AnyView(CodeDashboardBridge(
            box: state,
            onAction: { [weak self] index, action in self?.perform(action, at: index) },
            onRemove: { [weak self] index in self?.remove(at: index) },
            onDrop: { [weak self] urls in self?.pin(urls) }
        ))
    }

    func wideBarView() -> AnyView? {
        AnyView(CodeWideBarBridge(box: state))
    }

    func activate() {
        startTimer()
        Task { @MainActor in await refresh() }
    }

    func deactivate() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() async {
        let entries: [(String, String)] = store.projects.compactMap { project in
            guard let url = store.resolve(project) else { return nil }
            return (project.name, url.path)
        }
        let displays = await Task.detached {
            entries.map { CodeProjectDisplay(name: $0.0, status: GitProbe.status(atPath: $0.1)) }
        }.value
        state.projects = displays
    }

    private func pin(_ urls: [URL]) {
        let folders = urls.filter {
            (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }
        guard !folders.isEmpty else { return }
        folders.forEach { store.add($0) }
        Task { @MainActor in await refresh() }
    }

    private func remove(at index: Int) {
        store.remove(at: index)
        Task { @MainActor in await refresh() }
    }

    private func perform(_ action: CodeAction, at index: Int) {
        guard store.projects.indices.contains(index),
              let url = store.resolve(store.projects[index]) else { return }
        Launcher.perform(action, path: url.path)
    }

    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
    }
}

private struct CodeBridge: View {
    @ObservedObject var box: CodeModule.StateBox
    let onAction: (Int, CodeAction) -> Void
    let onRemove: (Int) -> Void
    let onDrop: ([URL]) -> Void

    var body: some View {
        CodeExpandedView(
            projects: box.projects,
            onAction: onAction,
            onRemove: onRemove,
            onDrop: onDrop
        )
    }
}

private struct CodeDashboardBridge: View {
    @ObservedObject var box: CodeModule.StateBox
    let onAction: (Int, CodeAction) -> Void
    let onRemove: (Int) -> Void
    let onDrop: ([URL]) -> Void

    var body: some View {
        CodeDashboardTile(
            projects: box.projects,
            onAction: onAction,
            onRemove: onRemove,
            onDrop: onDrop
        )
    }
}

private struct CodeWideBarBridge: View {
    @ObservedObject var box: CodeModule.StateBox

    var body: some View {
        CodeWideBar(projects: box.projects)
    }
}
