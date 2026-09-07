import SwiftUI

/// Thin "is playing" glance shown in the collapsed notch bar.
struct MediaCollapsedView: View {
    @Environment(\.notchTokens) private var tokens
    let isPlaying: Bool

    var body: some View {
        if isPlaying {
            Image(systemName: "waveform")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
                // Static glyph under Reduce Motion — no repeating animation.
                .symbolEffect(.variableColor.iterative, options: .repeating,
                              isActive: tokens.motionStyle != .reduced)
                .accessibilityLabel("Music playing")
        }
    }
}

/// Full now-playing card shown when the notch is expanded (compact hover panel).
/// Intentionally compact — no progress bar — so it doesn't crowd other modules.
struct MediaExpandedView: View {
    @Environment(\.notchTokens) private var tokens
    let np: NowPlaying?
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void

    var body: some View {
        if let np {
            HStack(spacing: 10) {
                ArtworkView(url: np.artworkURL, size: 44)

                VStack(alignment: .leading, spacing: 5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(np.title)
                            .font(tokens.titleFont)
                            .foregroundStyle(tokens.textPrimary)
                            .lineLimit(1)
                        Text("\(np.artist) · \(np.app)")
                            .font(tokens.captionFont)
                            .foregroundStyle(tokens.textSecondary)
                            .lineLimit(1)
                    }
                    TransportControls(isPlaying: np.isPlaying,
                                      onPrevious: onPrevious,
                                      onPlayPause: onPlayPause,
                                      onNext: onNext)
                }
                Spacer(minLength: 0)
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "music.note")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(tokens.textTertiary)
                Text("Nothing playing")
                    .font(tokens.bodyFont)
                    .foregroundStyle(tokens.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Shared previous / play-pause / next cluster with proper hover + press states.
private struct TransportControls: View {
    let isPlaying: Bool
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            NotchIconButton(systemName: "backward.fill", accessibilityLabel: "Previous track",
                            size: 24, iconSize: 11, action: onPrevious)
            NotchIconButton(systemName: isPlaying ? "pause.fill" : "play.fill",
                            accessibilityLabel: isPlaying ? "Pause" : "Play",
                            size: 26, iconSize: 13, isActive: true, action: onPlayPause)
            NotchIconButton(systemName: "forward.fill", accessibilityLabel: "Next track",
                            size: 24, iconSize: 11, action: onNext)
        }
    }
}

private struct ArtworkView: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                            .frame(width: size, height: size)
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 0.75)
        )
        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.30, green: 0.30, blue: 0.38), Color(red: 0.16, green: 0.16, blue: 0.22)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Image(systemName: "music.note")
                .font(.system(size: size * 0.34, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
}

/// Now-playing widget for the dashboard layout: artwork, track, transport, and live lyrics.
struct MediaDashboardTile: View {
    @Environment(\.notchTokens) private var tokens
    let np: NowPlaying?
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void

    var body: some View {
        NotchTile("Now Playing", systemImage: "music.note") {
            if let np {
                nowPlayingBody(np)
            } else {
                nothingPlayingView
            }
        } trailing: {
            if let np, np.isPlaying {
                Image(systemName: "waveform")
                    .symbolEffect(.variableColor.iterative, options: .repeating,
                                  isActive: tokens.motionStyle != .reduced)
                    .foregroundStyle(tokens.accent.opacity(0.8))
            }
        }
    }

    private func nowPlayingBody(_ np: NowPlaying) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ArtworkView(url: np.artworkURL, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(np.title)
                        .font(tokens.titleFont)
                        .foregroundStyle(tokens.textPrimary)
                        .lineLimit(1)
                    Text(np.artist)
                        .font(tokens.captionFont)
                        .foregroundStyle(tokens.textSecondary)
                        .lineLimit(1)
                    TransportControls(isPlaying: np.isPlaying,
                                      onPrevious: onPrevious,
                                      onPlayPause: onPlayPause,
                                      onNext: onNext)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }

            LyricsView(lyricsResult: np.lyricsResult, elapsed: np.elapsed)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var nothingPlayingView: some View {
        VStack(spacing: 10) {
            ModuleEmptyStateView(
                title: "No Active Track",
                message: "Start Music or Spotify to control playback here.",
                systemImage: "music.note"
            )
            spotifyButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var spotifyButton: some View {
        let spotifyGreen = Color(red: 0.11, green: 0.73, blue: 0.33)
        let isRunning = NSWorkspace.shared.runningApplications
            .contains { $0.bundleIdentifier == "com.spotify.client" }
        return Button {
            NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: "/Applications/Spotify.app"),
                configuration: NSWorkspace.OpenConfiguration())
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(spotifyGreen.opacity(0.22))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(spotifyGreen)
                    )
                Text(isRunning ? "Open Spotify" : "Launch Spotify")
            }
        }
        .buttonStyle(.notchSoft)
    }
}

// MARK: - Live lyrics view

private struct LyricsView: View {
    let lyricsResult: LyricsResult?
    let elapsed: Double?

    var body: some View {
        if let result = lyricsResult {
            if result.hasSynced {
                SyncedLyricsView(lines: result.synced, elapsed: elapsed ?? 0)
            } else if let plain = result.plain, !plain.isEmpty {
                PlainLyricsView(text: plain)
            }
        }
        // nil = still loading; show nothing
    }
}

private struct SyncedLyricsView: View {
    @Environment(\.notchTokens) private var tokens
    let lines: [LyricsLine]
    let elapsed: Double

    private var currentIndex: Int {
        var best = 0
        for (i, line) in lines.enumerated() {
            if line.time <= elapsed { best = i }
        }
        return best
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                        let isCurrent = i == currentIndex
                        Text(line.text)
                            .font(.system(size: isCurrent ? 12 : 10,
                                          weight: isCurrent ? .semibold : .regular))
                            .foregroundStyle(isCurrent ? tokens.textPrimary : tokens.textTertiary.opacity(0.75))
                            .blur(radius: isCurrent ? 0 : 0.3)
                            .animation(.easeOut(duration: 0.25), value: isCurrent)
                            .id(i)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.80),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .onChange(of: currentIndex) { _, idx in
                withAnimation(.easeOut(duration: 0.4)) {
                    proxy.scrollTo(max(0, idx - 2), anchor: .top)
                }
            }
        }
    }
}

private struct PlainLyricsView: View {
    @Environment(\.notchTokens) private var tokens
    let text: String

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(text)
                .font(tokens.captionFont.weight(.regular))
                .foregroundStyle(tokens.textTertiary)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: 0.80),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            )
        )
    }
}

/// Inline now-playing summary with a play/pause toggle for the wide bar.
struct MediaWideBar: View {
    @Environment(\.notchTokens) private var tokens
    let np: NowPlaying?
    let onPlayPause: () -> Void

    var body: some View {
        if let np {
            HStack(spacing: 6) {
                NotchIconButton(systemName: np.isPlaying ? "pause.fill" : "play.fill",
                                accessibilityLabel: np.isPlaying ? "Pause" : "Play",
                                size: 22, iconSize: 11, action: onPlayPause)
                Text(np.marquee)
                    .font(tokens.labelFont)
                    .foregroundStyle(tokens.textPrimary)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}
