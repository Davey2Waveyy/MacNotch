import Foundation

public struct LyricsLine: Equatable, Sendable {
    public var time: Double  // seconds
    public var text: String
}

public struct LyricsResult: Equatable, Sendable {
    /// Synced lines with timestamps when available.
    public var synced: [LyricsLine]
    /// Plain fallback (no timestamps).
    public var plain: String?

    public var hasSynced: Bool { !synced.isEmpty }

    /// The index of the current line given elapsed seconds.
    public func currentLineIndex(elapsed: Double) -> Int? {
        guard !synced.isEmpty else { return nil }
        // Last line whose timestamp is <= elapsed
        var best = 0
        for (i, line) in synced.enumerated() {
            if line.time <= elapsed { best = i }
        }
        return best
    }
}

enum LyricsFetcher {
    static func fetch(title: String, artist: String) async -> LyricsResult? {
        let encodedTitle  = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let encodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artist
        guard let url = URL(string: "https://lrclib.net/api/get?track_name=\(encodedTitle)&artist_name=\(encodedArtist)") else {
            return nil
        }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue(NotchBrand.userAgent, forHTTPHeaderField: "User-Agent")
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let synced = (json["syncedLyrics"] as? String).map(parseSynced) ?? []
        let plain  = json["plainLyrics"] as? String

        if synced.isEmpty && (plain == nil || plain!.isEmpty) { return nil }
        return LyricsResult(synced: synced, plain: plain)
    }

    // Parses "[mm:ss.xx] text\n..." into LyricsLine array.
    private static func parseSynced(_ raw: String) -> [LyricsLine] {
        raw.components(separatedBy: "\n").compactMap { line in
            guard line.hasPrefix("["),
                  let close = line.firstIndex(of: "]") else { return nil }
            let timestamp = String(line[line.index(after: line.startIndex)..<close])
            let text = String(line[line.index(after: close)...]).trimmingCharacters(in: .whitespaces)
            // Parse mm:ss.xx
            let parts = timestamp.components(separatedBy: ":")
            guard parts.count == 2,
                  let minutes = Double(parts[0]),
                  let seconds = Double(parts[1]) else { return nil }
            return LyricsLine(time: minutes * 60 + seconds, text: text)
        }
        .filter { !$0.text.isEmpty }
    }
}
