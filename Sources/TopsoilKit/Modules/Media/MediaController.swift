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
        let snapshots = sources.compactMap { source -> (source: MediaSource, np: NowPlaying)? in
            guard source.isAvailable, let np = source.nowPlaying() else { return nil }
            return (source, np)
        }

        if let playing = snapshots.first(where: { $0.np.isPlaying }) {
            return playing
        }

        return snapshots.first
    }
}
