import Foundation

public enum ScreenTimeFormat {
    private static func hms(_ seconds: TimeInterval) -> (h: Int, m: Int, s: Int) {
        let t = Int(seconds.rounded())
        return (t / 3600, (t % 3600) / 60, t % 60)
    }

    /// Compact duration like "1h 13m", "47m", or "38s".
    public static func duration(_ seconds: TimeInterval) -> String {
        let (h, m, s) = hms(seconds)
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(s)s"
    }

    /// Short label for a per-app row, e.g. "21m".
    public static func short(_ seconds: TimeInterval) -> String {
        let (h, m, _) = hms(seconds)
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        if m > 0 { return "\(m)m" }
        return "\(Int(seconds.rounded()))s"
    }
}
