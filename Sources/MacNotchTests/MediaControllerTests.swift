import MacNotchKit

func mediaControllerTests() {
    final class Fake: MediaSource {
        let name: String
        var isAvailable: Bool
        var stored: NowPlaying?
        init(_ name: String, available: Bool, np: NowPlaying?) {
            self.name = name
            self.isAvailable = available
            self.stored = np
        }
        func nowPlaying() -> NowPlaying? { isAvailable ? stored : nil }
        func playPause() {}
        func next() {}
        func previous() {}
    }

    func track(_ title: String, playing: Bool) -> NowPlaying {
        NowPlaying(title: title, artist: "artist", app: "app",
                   isPlaying: playing, elapsed: nil, duration: nil)
    }

    test("media: a playing source beats a paused one") {
        let paused = Fake("Music", available: true, np: track("A", playing: false))
        let playing = Fake("Spotify", available: true, np: track("B", playing: true))
        let controller = MediaController(sources: [paused, playing])
        expect(controller.active()?.np.title == "B", "playing source wins")
    }

    test("media: falls back to any track when none are playing") {
        let paused = Fake("Music", available: true, np: track("A", playing: false))
        let controller = MediaController(sources: [paused])
        expect(controller.active()?.np.title == "A", "any available track is used")
    }

    test("media: unavailable sources are skipped") {
        let dead = Fake("MediaRemote", available: false, np: track("Z", playing: true))
        let live = Fake("Music", available: true, np: track("A", playing: false))
        let controller = MediaController(sources: [dead, live])
        expect(controller.active()?.source.name == "Music", "unavailable source ignored")
    }

    test("media: returns nil when nothing is available") {
        let controller = MediaController(sources: [Fake("MediaRemote", available: false, np: nil)])
        expect(controller.active() == nil, "no active media")
    }

    test("media: progress is the elapsed/duration fraction") {
        let np = NowPlaying(title: "t", artist: "a", app: "x",
                            isPlaying: true, elapsed: 30, duration: 120)
        expect(np.progress == 0.25, "quarter through")
        let noDuration = NowPlaying(title: "t", artist: "a", app: "x",
                                    isPlaying: true, elapsed: 30, duration: nil)
        expect(noDuration.progress == nil, "no progress without duration")
    }
}
