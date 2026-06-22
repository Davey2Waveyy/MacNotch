import SwiftUI

@MainActor
final class MediaModule: NotchModule {
    let id = "media"
    let title = "Now Playing"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var np: NowPlaying?
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

    func activate() {
        startTimer()
        Task { @MainActor in await refresh() }
    }

    func deactivate() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() async {
        state.np = controller.active()?.np
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
            onPrevious: { controller.active()?.source.previous(); onAction() },
            onPlayPause: { controller.active()?.source.playPause(); onAction() },
            onNext: { controller.active()?.source.next(); onAction() }
        )
    }
}
