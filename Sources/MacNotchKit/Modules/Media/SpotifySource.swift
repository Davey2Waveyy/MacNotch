import AppKit

/// Spotify media source driven entirely by distributed notifications — no polling.
///
/// - **Playback state**: `com.spotify.client.PlaybackStateChanged` fires on every
///   track change and play/pause event. No timer needed.
/// - **Elapsed extrapolation**: notifications carry a snapshot position. We record
///   the wall-clock time of each snapshot and extrapolate forward so synced lyrics
///   stay current between notification firings.
/// - **App lifecycle**: NSWorkspace notifications detect when Spotify launches or
///   quits so we can seed/clear state without polling.
public final class SpotifySource: MediaSource, @unchecked Sendable {
    public let name = "Spotify"
    private let bundleID = "com.spotify.client"
    public var onChange: (() -> Void)?

    private var notifState: NowPlaying?
    private var notifElapsed: Double = 0
    private var notifTimestamp: Date = .distantPast
    private var notifIsPlaying = false
    private var lastProbeAttempt: Date = .distantPast

    private var playbackObserver: NSObjectProtocol?
    private var launchObserver: NSObjectProtocol?
    private var quitObserver: NSObjectProtocol?
    private var lastLyricsKey: String?

    public init() {
        playbackObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] note in
            self?.ingest(note.userInfo as? [String: Any] ?? [:])
        }

        launchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == self?.bundleID else { return }
            self?.probeInitialState()
            self?.notifyChanged()
        }

        quitObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == self?.bundleID else { return }
            self?.clearState()
        }
    }

    deinit {
        if let playbackObserver { DistributedNotificationCenter.default().removeObserver(playbackObserver) }
        if let launchObserver  { NSWorkspace.shared.notificationCenter.removeObserver(launchObserver) }
        if let quitObserver    { NSWorkspace.shared.notificationCenter.removeObserver(quitObserver) }
    }

    public var isAvailable: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleID }
    }

    public var needsFallbackProbe: Bool {
        isAvailable && notifState == nil
    }

    /// Returns a copy of the current state with elapsed extrapolated forward from
    /// the last notification timestamp — keeps synced lyrics tracking in real time.
    public func nowPlaying() -> NowPlaying? {
        guard var np = notifState else { return nil }
        if notifIsPlaying {
            let extrapolated = notifElapsed + Date().timeIntervalSince(notifTimestamp)
            np.elapsed = extrapolated
        }
        return np
    }

    /// Probe Spotify's current state at activation time (and on app launch).
    public func probeInitialState() {
        guard isAvailable else { return }
        Task { @MainActor [weak self] in
            guard let self, self.notifState == nil else { return }
            // NSAppleScript must execute on the main thread — no Task.detached here.
            let np = SpotifySource.scriptQuery()
            guard let np, self.notifState == nil else { return }
            self.notifState = np
            self.notifElapsed = np.elapsed ?? 0
            self.notifTimestamp = Date()
            self.notifIsPlaying = np.isPlaying
            let key = "\(np.title)|\(np.artist)"
            self.lastLyricsKey = key
            self.notifyChanged()
            let result = await LyricsFetcher.fetch(title: np.title, artist: np.artist)
            if self.lastLyricsKey == key {
                self.notifState?.lyricsResult = result
                self.notifyChanged()
            }
        }
    }

    /// Rate-limited fallback probe for Spotify versions that don't fire distributed notifications.
    /// Safe to call frequently — internally throttled to once every 8 seconds.
    func probeIfNeeded() {
        guard isAvailable, notifState == nil else { return }
        let now = Date()
        guard now.timeIntervalSince(lastProbeAttempt) > 8 else { return }
        lastProbeAttempt = now
        probeInitialState()
    }

    // MARK: - Controls

    public func playPause() { script("tell application \"Spotify\" to playpause") }
    public func next()      { script("tell application \"Spotify\" to next track") }
    public func previous()  { script("tell application \"Spotify\" to previous track") }

    // MARK: - Private

    private func ingest(_ info: [String: Any]) {
        let state = info["Player State"] as? String ?? "Stopped"
        guard state != "Stopped" else {
            clearState()
            return
        }

        let isPlaying = state == "Playing"
        let elapsed   = info["Playback Position"] as? Double ?? 0
        let durationMs = info["Duration"] as? Double
        let artworkURL = (info["Image URL"] as? String).flatMap(URL.init(string:))
        let title  = info["Name"] as? String ?? ""
        let artist = info["Artist"] as? String ?? ""

        // Record snapshot for extrapolation.
        notifElapsed   = elapsed
        notifTimestamp = Date()
        notifIsPlaying = isPlaying

        let prevLyrics = notifState?.lyricsResult
        notifState = NowPlaying(
            title: title,
            artist: artist,
            app: "Spotify",
            isPlaying: isPlaying,
            elapsed: elapsed,
            duration: durationMs.map { $0 / 1000 },
            artworkURL: artworkURL,
            lyricsResult: prevLyrics
        )

        if artworkURL == nil {
            Task { @MainActor [weak self] in
                guard let self else { return }
                let url = await Task.detached(priority: .utility) { SpotifySource.fetchArtworkURL() }.value
                self.notifState?.artworkURL = url
                self.notifyChanged()
            }
        }

        let lyricsKey = "\(title)|\(artist)"
        if lyricsKey != lastLyricsKey {
            lastLyricsKey = lyricsKey
            notifState?.lyricsResult = nil  // clear stale lyrics immediately
            Task { @MainActor [weak self] in
                guard let self else { return }
                let result = await LyricsFetcher.fetch(title: title, artist: artist)
                if self.lastLyricsKey == lyricsKey {
                    self.notifState?.lyricsResult = result
                    self.notifyChanged()
                }
            }
        }
        notifyChanged()
    }

    private func clearState() {
        notifState = nil
        notifElapsed = 0
        notifTimestamp = .distantPast
        notifIsPlaying = false
        lastLyricsKey = nil
        notifyChanged()
    }

    private func notifyChanged() {
        onChange?()
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
