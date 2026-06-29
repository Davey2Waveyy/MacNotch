import Foundation

/// A snapshot of whatever is currently playing in a media source.
public struct NowPlaying: Equatable, Sendable {
    public var title: String
    public var artist: String
    public var app: String
    public var isPlaying: Bool
    public var elapsed: Double?
    public var duration: Double?
    public var artworkURL: URL?
    public var lyricsResult: LyricsResult?

    public init(
        title: String,
        artist: String,
        app: String,
        isPlaying: Bool,
        elapsed: Double?,
        duration: Double?,
        artworkURL: URL? = nil,
        lyricsResult: LyricsResult? = nil
    ) {
        self.title = title
        self.artist = artist
        self.app = app
        self.isPlaying = isPlaying
        self.elapsed = elapsed
        self.duration = duration
        self.artworkURL = artworkURL
        self.lyricsResult = lyricsResult
    }

    /// Playback fraction in 0...1 when both elapsed and duration are known.
    public var progress: Double? {
        guard let elapsed, let duration, duration > 0 else { return nil }
        return min(max(elapsed / duration, 0), 1)
    }

    /// One-line "Title — Artist" summary for the wide-bar strip. Drops the
    /// dash when the artist is empty so it never reads "Title — ".
    public var marquee: String {
        let trimmedArtist = artist.trimmingCharacters(in: .whitespaces)
        return trimmedArtist.isEmpty ? title : "\(title) — \(trimmedArtist)"
    }
}

public enum MediaRefreshPolicy {
    public static let elapsedTickInterval: TimeInterval = 0.5

    public static func needsElapsedTick(isPlaying: Bool, hasSyncedLyrics: Bool) -> Bool {
        isPlaying && hasSyncedLyrics
    }

    public static func needsElapsedTick(for nowPlaying: NowPlaying?) -> Bool {
        needsElapsedTick(
            isPlaying: nowPlaying?.isPlaying == true,
            hasSyncedLyrics: nowPlaying?.lyricsResult?.hasSynced == true
        )
    }
}
