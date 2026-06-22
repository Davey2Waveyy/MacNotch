import SwiftUI

@MainActor
final class MediaModule: NotchModule {
    let id = "media"
    let title = "Now Playing"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var np: NowPlaying?
        var activeSource: MediaSource?
    }

    private let state = StateBox()
    private let controller = MediaController(sources: [
        MediaRemoteSource(),
        AppleScriptSource(appName: "Music"),
        AppleScriptSource(appName: "Spotify"),
    ])
    private var timer: Timer?

    func collapsedView() -> AnyView? {
        AnyView(MediaCollapsedBridge(box: state))
    }

    func expandedView() -> AnyView {
        AnyView(MediaExpandedBridge(box: state, controller: controller) { [weak self] in
            Task { @MainActor [weak self] in await self?.refresh() }
        })
    }

    func dashboardTile() -> AnyView? {
        AnyView(MediaDashboardBridge(box: state, controller: controller) { [weak self] in
            Task { @MainActor [weak self] in await self?.refresh() }
        })
    }

    func wideBarView() -> AnyView? {
        AnyView(MediaWideBarBridge(box: state, controller: controller) { [weak self] in
            Task { @MainActor [weak self] in await self?.refresh() }
        })
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
        let active = controller.active()
        state.activeSource = active?.source
        state.np = active?.np
    }

    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
    }
}

private struct MediaCollapsedBridge: View {
    @ObservedObject var box: MediaModule.StateBox
    var body: some View {
        MediaCollapsedView(isPlaying: box.np?.isPlaying == true)
    }
}

private struct MediaExpandedBridge: View {
    @ObservedObject var box: MediaModule.StateBox
    let controller: MediaController
    let onAction: () -> Void

    var body: some View {
        MediaExpandedView(
            np: box.np,
            onPrevious: {
                (box.activeSource ?? controller.active()?.source)?.previous()
                onAction()
            },
            onPlayPause: {
                (box.activeSource ?? controller.active()?.source)?.playPause()
                onAction()
            },
            onNext: {
                (box.activeSource ?? controller.active()?.source)?.next()
                onAction()
            }
        )
    }
}

private struct MediaDashboardBridge: View {
    @ObservedObject var box: MediaModule.StateBox
    let controller: MediaController
    let onAction: () -> Void

    var body: some View {
        MediaDashboardTile(
            np: box.np,
            onPrevious: {
                (box.activeSource ?? controller.active()?.source)?.previous()
                onAction()
            },
            onPlayPause: {
                (box.activeSource ?? controller.active()?.source)?.playPause()
                onAction()
            },
            onNext: {
                (box.activeSource ?? controller.active()?.source)?.next()
                onAction()
            }
        )
    }
}

private struct MediaWideBarBridge: View {
    @ObservedObject var box: MediaModule.StateBox
    let controller: MediaController
    let onAction: () -> Void

    var body: some View {
        MediaWideBar(np: box.np) {
            (box.activeSource ?? controller.active()?.source)?.playPause()
            onAction()
        }
    }
}
