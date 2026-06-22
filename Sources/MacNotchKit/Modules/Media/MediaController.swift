import Foundation

/// Aggregates several `MediaSource`s and picks the one to display/control.
///
/// Selection: among available sources, a source that is currently *playing* wins;
/// otherwise the first available source that has any track. Order of `sources`
/// breaks ties.
public final class MediaController {
    private let sources: [MediaSource]

    public init(sources: [MediaSource]) {
        self.sources = sources
    }

    public func active() -> (source: MediaSource, np: NowPlaying)? {
        let live = sources.filter { $0.isAvailable }

        if let playing = live.first(where: { $0.nowPlaying()?.isPlaying == true }),
           let np = playing.nowPlaying() {
            return (playing, np)
        }

        for source in live {
            if let np = source.nowPlaying() {
                return (source, np)
            }
        }
        return nil
    }
}
