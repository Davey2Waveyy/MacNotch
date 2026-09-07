import SwiftUI

@MainActor
final class ShelfModule: NotchModule {
    let id = "shelf"
    let title = "Drop Shelf"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var items: [ShelfItem] = []
    }

    private let state = StateBox()
    private let store: ShelfStore

    init(store: ShelfStore = ShelfStore(url: ShelfStore.defaultURL())) {
        self.store = store
        state.items = store.items
    }

    func collapsedView() -> AnyView? {
        AnyView(ShelfCollapsedBridge(box: state))
    }

    func expandedView() -> AnyView? {
        AnyView(ShelfExpandedBridge(
            box: state,
            onDrop: { [weak self] urls in
                guard let self else { return }
                urls.forEach { self.store.add($0) }
                self.state.items = self.store.items
            },
            onRemove: { [weak self] index in
                guard let self else { return }
                self.store.remove(at: index)
                self.state.items = self.store.items
            },
            resolve: { [weak self] item in self?.store.resolve(item) }
        ))
    }

    func dashboardTile() -> AnyView? {
        AnyView(ShelfDashboardBridge(
            box: state,
            onDrop: { [weak self] urls in
                guard let self else { return }
                urls.forEach { self.store.add($0) }
                self.state.items = self.store.items
            },
            onRemove: { [weak self] index in
                guard let self else { return }
                self.store.remove(at: index)
                self.state.items = self.store.items
            },
            resolve: { [weak self] item in self?.store.resolve(item) }
        ))
    }

    func wideBarView() -> AnyView? {
        AnyView(ShelfWideBarBridge(box: state))
    }

    func acceptDrop(_ urls: [URL]) {
        urls.forEach { store.add($0) }
        state.items = store.items
    }

    func activate() {
        state.items = store.items
    }

    func deactivate() {}

    func refresh() async {}
}

private struct ShelfCollapsedBridge: View {
    @ObservedObject var box: ShelfModule.StateBox
    var body: some View {
        ShelfCollapsedView(count: box.items.count)
    }
}

private struct ShelfExpandedBridge: View {
    @ObservedObject var box: ShelfModule.StateBox
    let onDrop: ([URL]) -> Void
    let onRemove: (Int) -> Void
    let resolve: (ShelfItem) -> URL?

    var body: some View {
        ShelfExpandedView(items: box.items, onDrop: onDrop, onRemove: onRemove, resolve: resolve)
    }
}

private struct ShelfDashboardBridge: View {
    @ObservedObject var box: ShelfModule.StateBox
    let onDrop: ([URL]) -> Void
    let onRemove: (Int) -> Void
    let resolve: (ShelfItem) -> URL?

    var body: some View {
        ShelfDashboardTile(items: box.items, onDrop: onDrop, onRemove: onRemove, resolve: resolve)
    }
}

private struct ShelfWideBarBridge: View {
    @ObservedObject var box: ShelfModule.StateBox

    var body: some View {
        ShelfWideBar(count: box.items.count)
    }
}
