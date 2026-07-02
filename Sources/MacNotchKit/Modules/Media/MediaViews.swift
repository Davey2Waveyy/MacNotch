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
    let np: NowPlaying?
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void

    var body: some View {
        if let np {
            HStack(spacing: 10) {
                artworkView(url: np.artworkURL, size: 44)

                VStack(alignment: .leading, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(np.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("\(np.artist) · \(np.app)")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                    HStack(spacing: 20) {
                        controlButton("backward.fill", label: "Previous track", action: onPrevious)
                        controlButton(np.isPlaying ? "pause.fill" : "play.fill",
                                      label: np.isPlaying ? "Pause" : "Play", action: onPlayPause)
                        controlButton("forward.fill", label: "Next track", action: onNext)
                    }
                }
                Spacer(minLength: 0)
            }
        } else {
            Text("Nothing playing")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func controlButton(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                // Pad the tap target toward 30pt without changing the glyph size.
                .contentShape(Rectangle().inset(by: -8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

@ViewBuilder
private func artworkView(url: URL?, size: CGFloat) -> some View {
    let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
    if let url {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(shape)
            default:
                musicNotePlaceholder(size: size)
            }
        }
        .frame(width: size, height: size)
    } else {
        musicNotePlaceholder(size: size)
    }
}

private func musicNotePlaceholder(size: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(LinearGradient(
            colors: [Color(red: 1, green: 0.42, blue: 0.62), Color(red: 0.65, green: 0.42, blue: 1)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ))
        .frame(width: size, height: size)
        .overlay(Image(systemName: "music.note").foregroundStyle(.white.opacity(0.85)))
}

/// Now-playing widget for the dashboard layout: artwork, track, transport, and live lyrics.
struct MediaDashboardTile: View {
    let np: NowPlaying?
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Now Playing", systemImage: "music.note")
            if let np {
                nowPlayingBody(np)
            } else {
                nothingPlayingView
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func nowPlayingBody(_ np: NowPlaying) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                artworkView(url: np.artworkURL, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(np.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(np.artist)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 20) {
                control("backward.fill", label: "Previous track", action: onPrevious)
                control(np.isPlaying ? "pause.fill" : "play.fill",
                        label: np.isPlaying ? "Pause" : "Play", action: onPlayPause)
                control("forward.fill", label: "Next track", action: onNext)
            }
            .padding(.top, 2)

            LyricsView(lyricsResult: np.lyricsResult, elapsed: np.elapsed)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 8)
    }

    private var nothingPlayingView: some View {
        VStack(spacing: 10) {
            ModuleEmptyStateView(
                title: "No Active Track",
                message: "Start Music or Spotify to control playback here.",
                systemImage: "music.note"
            )
            spotifyButton
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var spotifyButton: some View {
        let isRunning = NSWorkspace.shared.runningApplications
            .contains { $0.bundleIdentifier == "com.spotify.client" }
        return Button {
            NSWorkspace.shared.openApplication(
                at: URL(fileURLWithPath: "/Applications/Spotify.app"),
                configuration: NSWorkspace.OpenConfiguration())
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 0.11, green: 0.73, blue: 0.33).opacity(0.22))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(red: 0.11, green: 0.73, blue: 0.33))
                    )
                Text(isRunning ? "Open Spotify" : "Launch Spotify")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.75)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func control(_ systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                // Pad the tap target toward 30pt without changing the glyph size.
                .contentShape(Rectangle().inset(by: -8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
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
                            .foregroundStyle(isCurrent ? Color.white : Color.white.opacity(0.30))
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
    let text: String

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(text)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.white.opacity(0.40))
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
    let np: NowPlaying?
    let onPlayPause: () -> Void

    var body: some View {
        if let np {
            HStack(spacing: 8) {
                Button(action: onPlayPause) {
                    Image(systemName: np.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        // Pad the tap target toward 30pt without changing the glyph size.
                        .contentShape(Rectangle().inset(by: -8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(np.isPlaying ? "Pause" : "Play")
                Text(np.marquee)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}
