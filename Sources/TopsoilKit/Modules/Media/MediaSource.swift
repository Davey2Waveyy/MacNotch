import Foundation

/// A backend that can report and control "now playing" media.
///
/// Phase 1 ships `AppleScriptSource` (reliable, per-app) plus an opportunistic
/// `MediaRemoteSource`. Everything is funnelled through this protocol so a future
/// universal backend can be dropped in without touching callers.
public protocol MediaSource: AnyObject {
    var name: String { get }
    var isAvailable: Bool { get }
    func nowPlaying() -> NowPlaying?
    func playPause()
    func next()
    func previous()
}
