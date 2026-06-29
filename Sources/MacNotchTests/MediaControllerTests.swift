import MacNotchKit

func mediaControllerTests() {
    final class Fake: MediaSource {
        let name: String
        var isAvailable: Bool
        var stored: NowPlaying?
        var probeCount = 0
        init(_ name: String, available: Bool, np: NowPlaying?) {
            self.name = name
            self.isAvailable = available
            self.stored = np
        }
        func nowPlaying() -> NowPlaying? {
            probeCount += 1
            return isAvailable ? stored : nil
        }
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

    test("media: active snapshots each available source once per call") {
        let first = Fake("Music", available: true, np: track("A", playing: false))
        let second = Fake("Spotify", available: true, np: track("B", playing: true))
        let third = Fake("Browser", available: true, np: track("C", playing: false))
        let controller = MediaController(sources: [first, second, third])

        expect(controller.active()?.np.title == "B", "playing snapshot still wins")
        expectEqual(first.probeCount, 1, "first source probed once")
        expectEqual(second.probeCount, 1, "second source probed once")
        expectEqual(third.probeCount, 1, "third source probed once")
    }

    test("media: source order breaks ties for playing snapshots") {
        let first = Fake("Music", available: true, np: track("A", playing: true))
        let second = Fake("Spotify", available: true, np: track("B", playing: true))
        let controller = MediaController(sources: [first, second])

        expect(controller.active()?.source.name == "Music", "first playing source wins tie")
    }

    test("media: source order breaks ties for paused track snapshots") {
        let first = Fake("Music", available: true, np: track("A", playing: false))
        let second = Fake("Spotify", available: true, np: track("B", playing: false))
        let controller = MediaController(sources: [first, second])

        expect(controller.active()?.source.name == "Music", "first paused track wins tie")
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

    test("media: progress clamps below zero") {
        let np = NowPlaying(title: "t", artist: "a", app: "x",
                            isPlaying: true, elapsed: -5, duration: 120)
        expectEqual(np.progress, 0, "negative elapsed clamps to zero")
    }

    test("media: progress clamps above one") {
        let np = NowPlaying(title: "t", artist: "a", app: "x",
                            isPlaying: true, elapsed: 130, duration: 120)
        expectEqual(np.progress, 1, "elapsed beyond duration clamps to one")
    }

    test("media: marquee joins title and artist") {
        let np = NowPlaying(title: "Song", artist: "Band", app: "Music",
                            isPlaying: true, elapsed: nil, duration: nil)
        expectEqual(np.marquee, "Song — Band", "title and artist joined")
    }

    test("media: marquee drops the dash when artist is blank") {
        let np = NowPlaying(title: "Podcast", artist: "  ", app: "Music",
                            isPlaying: true, elapsed: nil, duration: nil)
        expectEqual(np.marquee, "Podcast", "no trailing dash for blank artist")
    }

    test("media: elapsed refresh policy only ticks playing synced lyrics") {
        expect(
            MediaRefreshPolicy.needsElapsedTick(isPlaying: true, hasSyncedLyrics: true),
            "playing synced lyrics need elapsed ticks"
        )
        expect(
            !MediaRefreshPolicy.needsElapsedTick(isPlaying: true, hasSyncedLyrics: false),
            "playing media without synced lyrics does not need elapsed ticks"
        )
        expect(
            !MediaRefreshPolicy.needsElapsedTick(isPlaying: false, hasSyncedLyrics: true),
            "paused synced lyrics do not need elapsed ticks"
        )
    }
}
