import AppKit

/// Reads and controls Music.app or Spotify.app via AppleScript. Reliable and
/// entitlement-free (gated only by Automation TCC). `appName` is "Music" or "Spotify".
public final class AppleScriptSource: MediaSource {
    public let name: String
    private let appName: String
    private let bundleID: String

    public init(appName: String) {
        self.appName = appName
        self.name = appName
        self.bundleID = appName == "Music" ? "com.apple.Music" : "com.spotify.client"
    }

    public var isAvailable: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleID }
    }

    public func nowPlaying() -> NowPlaying? {
        guard isAvailable else { return nil }
        let script = """
        tell application "\(appName)"
            if it is running and player state is not stopped then
                set st to player state as text
                set t to name of current track
                set a to artist of current track
                set pos to player position
                set dur to (duration of current track)
                return st & "|~|" & t & "|~|" & a & "|~|" & pos & "|~|" & dur
            end if
        end tell
        """
        guard let out = run(script) else { return nil }
        let parts = out.components(separatedBy: "|~|")
        guard parts.count >= 5 else { return nil }

        let isPlaying = parts[0].contains("playing")
        let elapsed = Double(parts[3])
        // Music reports duration in seconds; Spotify in milliseconds.
        let rawDuration = Double(parts[4])
        let duration = appName == "Spotify" ? rawDuration.map { $0 / 1000 } : rawDuration

        return NowPlaying(
            title: parts[1],
            artist: parts[2],
            app: appName,
            isPlaying: isPlaying,
            elapsed: elapsed,
            duration: duration
        )
    }

    public func playPause() { run("tell application \"\(appName)\" to playpause") }
    public func next() { run("tell application \"\(appName)\" to next track") }
    public func previous() { run("tell application \"\(appName)\" to previous track") }

    @discardableResult
    private func run(_ source: String) -> String? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if error != nil { return nil }
        return result?.stringValue
    }
}
