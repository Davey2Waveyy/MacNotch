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
    private let spotify = SpotifySource()
    private lazy var controller = MediaController(sources: [spotify])
    private var fallbackProbeTimer: Timer?
    private var elapsedTimer: Timer?

    func collapsedView() -> AnyView? {
        AnyView(MediaCollapsedBridge(box: state))
    }

    func expandedView() -> AnyView? {
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
        spotify.onChange = { [weak self] in
            Task { @MainActor [weak self] in self?.sourceDidChange() }
        }
        spotify.probeInitialState()
        refreshSnapshot()
    }

    func deactivate() {
        spotify.onChange = nil
        fallbackProbeTimer?.invalidate()
        fallbackProbeTimer = nil
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    func refresh() async {
        refreshSnapshot()
    }

    private func sourceDidChange() {
        refreshSnapshot()
    }

    private func refreshSnapshot() {
        let active = controller.active()
        state.activeSource = active?.source
        let next = active?.np
        if state.np != next {
            state.np = next
        }
        syncTimers()
    }

    private func syncTimers() {
        if spotify.needsFallbackProbe {
            startFallbackProbeTimerIfNeeded()
        } else {
            stopFallbackProbeTimer()
        }

        if MediaRefreshPolicy.needsElapsedTick(for: state.np) {
            startElapsedTimerIfNeeded()
        } else {
            stopElapsedTimer()
        }
    }

    private func startFallbackProbeTimerIfNeeded() {
        guard fallbackProbeTimer == nil else { return }
        let timer = Timer(timeInterval: 8, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Probe when Spotify is running but not yet detected (covers Spotify
                // versions that don't fire distributed notifications until first interaction,
                // and the case where the initial probe ran before MacNotch had TCC permission).
                self.spotify.probeIfNeeded()
                self.refreshSnapshot()
            }
        }
        timer.tolerance = 2
        fallbackProbeTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopFallbackProbeTimer() {
        fallbackProbeTimer?.invalidate()
        fallbackProbeTimer = nil
    }

    private func startElapsedTimerIfNeeded() {
        guard elapsedTimer == nil else { return }
        let timer = Timer(timeInterval: MediaRefreshPolicy.elapsedTickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshSnapshot() }
        }
        timer.tolerance = 0.1
        elapsedTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
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
