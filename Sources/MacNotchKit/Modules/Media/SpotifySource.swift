import AppKit

/// Spotify media source with two layers:
///
/// - **Distributed notifications** (`com.spotify.client.PlaybackStateChanged`): no
///   Automation TCC permission needed. Updates in real time whenever track or
///   playback state changes.
/// - **AppleScript probe** on `activate()`: runs once in the background to seed
///   the initial state (and trigger the TCC prompt the first time). Controls
///   (play/pause/next/prev) also use AppleScript so they work after TCC is granted.
public final class SpotifySource: MediaSource, @unchecked Sendable {
    public let name = "Spotify"
    private let bundleID = "com.spotify.client"

    private var notifState: NowPlaying?
    private var observer: NSObjectProtocol?

    public init() {
        observer = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.ingest(note.userInfo as? [String: Any] ?? [:])
        }
    }

    deinit {
        if let observer { DistributedNotificationCenter.default().removeObserver(observer) }
    }

    public var isAvailable: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleID }
    }

    public func nowPlaying() -> NowPlaying? { notifState }

    /// Call once when the module activates. Runs an AppleScript probe in the
    /// background so the current track appears immediately and the TCC prompt
    /// fires the first time instead of staying blank until the next state change.
    public func probeInitialState() {
        guard isAvailable else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let np = await Task.detached(priority: .utility) { SpotifySource.scriptQuery() }.value
            if self.notifState == nil { self.notifState = np }
        }
    }

    // MARK: - Controls (AppleScript — triggers TCC on first use)

    public func playPause() { script("tell application \"Spotify\" to playpause") }
    public func next()      { script("tell application \"Spotify\" to next track") }
    public func previous()  { script("tell application \"Spotify\" to previous track") }

    // MARK: - Private

    private func ingest(_ info: [String: Any]) {
        let state = info["Player State"] as? String ?? "Stopped"
        guard state != "Stopped" else { notifState = nil; return }
        // Spotify's PlaybackStateChanged carries Duration in milliseconds.
        let durationMs = info["Duration"] as? Double
        // Artwork URL is included in the notification payload as "Image URL".
        let artworkURL = (info["Image URL"] as? String).flatMap(URL.init(string:))
        notifState = NowPlaying(
            title: info["Name"] as? String ?? "",
            artist: info["Artist"] as? String ?? "",
            app: "Spotify",
            isPlaying: state == "Playing",
            elapsed: info["Playback Position"] as? Double,
            duration: durationMs.map { $0 / 1000 },
            artworkURL: artworkURL
        )
        // If notification didn't carry artwork, fetch it via AppleScript in the background.
        if artworkURL == nil {
            Task { @MainActor [weak self] in
                guard let self else { return }
                let url = await Task.detached(priority: .utility) { SpotifySource.fetchArtworkURL() }.value
                self.notifState?.artworkURL = url
            }
        }
    }

    @discardableResult
    private func script(_ source: String) -> String? {
        var err: NSDictionary?
        let r = NSAppleScript(source: source)?.executeAndReturnError(&err)
        return err == nil ? r?.stringValue : nil
    }

    private static func scriptQuery() -> NowPlaying? {
        let source = """
        tell application "Spotify"
            if player state is not stopped then
                set st     to player state as text
                set t      to name of current track
                set a      to artist of current track
                set pos    to player position
                set dur    to (duration of current track)
                set artURL to artwork url of current track
                return st & "|~|" & t & "|~|" & a & "|~|" & pos & "|~|" & dur & "|~|" & artURL
            end if
        end tell
        """
        var err: NSDictionary?
        guard let r = NSAppleScript(source: source)?.executeAndReturnError(&err),
              err == nil, let s = r.stringValue else { return nil }
        let p = s.components(separatedBy: "|~|")
        guard p.count >= 5 else { return nil }
        let artworkURL = p.count >= 6 ? URL(string: p[5]) : nil
        // AppleScript `duration` for Spotify is in milliseconds.
        return NowPlaying(
            title: p[1], artist: p[2], app: "Spotify",
            isPlaying: p[0].contains("playing"),
            elapsed: Double(p[3]),
            duration: Double(p[4]).map { $0 / 1000 },
            artworkURL: artworkURL
        )
    }

    private static func fetchArtworkURL() -> URL? {
        let source = """
        tell application "Spotify"
            if player state is not stopped then
                return artwork url of current track
            end if
        end tell
        """
        var err: NSDictionary?
        guard let r = NSAppleScript(source: source)?.executeAndReturnError(&err),
              err == nil, let s = r.stringValue else { return nil }
        return URL(string: s)
    }
}
