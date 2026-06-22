import Foundation

/// A snapshot of whatever is currently playing in a media source.
public struct NowPlaying: Equatable, Sendable {
    public var title: String
    public var artist: String
    public var app: String
    public var isPlaying: Bool
    public var elapsed: Double?
    public var duration: Double?

    public init(
        title: String,
        artist: String,
        app: String,
        isPlaying: Bool,
        elapsed: Double?,
        duration: Double?
    ) {
        self.title = title
        self.artist = artist
        self.app = app
        self.isPlaying = isPlaying
        self.elapsed = elapsed
        self.duration = duration
    }

    /// Playback fraction in 0...1 when both elapsed and duration are known.
    public var progress: Double? {
        guard let elapsed, let duration, duration > 0 else { return nil }
        return min(max(elapsed / duration, 0), 1)
    }
}
