import Foundation

/// Opportunistic private-framework source. On macOS 15.4+/26 the `MediaRemote`
/// now-playing API is locked down for third-party apps, so this reports
/// `isAvailable == false` and is skipped. It exists to keep the `MediaSource`
/// seam honest: a working universal backend can be dropped in here later with no
/// changes to `MediaController` or its callers.
public final class MediaRemoteSource: MediaSource {
    public let name = "MediaRemote"
    public init() {}

    public var isAvailable: Bool { false }
    public func nowPlaying() -> NowPlaying? { nil }
    public func playPause() {}
    public func next() {}
    public func previous() {}
}
