import SwiftUI

/// Thin "is playing" glance shown in the collapsed notch bar.
struct MediaCollapsedView: View {
    let isPlaying: Bool

    var body: some View {
        if isPlaying {
            Image(systemName: "waveform")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.variableColor.iterative, options: .repeating)
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
                        controlButton("backward.fill", action: onPrevious)
                        controlButton(np.isPlaying ? "pause.fill" : "play.fill", action: onPlayPause)
                        controlButton("forward.fill", action: onNext)
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

    private func controlButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
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

/// Now-playing widget for the dashboard layout: artwork, track, transport.
struct MediaDashboardTile: View {
    let np: NowPlaying?
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Now Playing", systemImage: "music.note")
            Spacer(minLength: 0)
            if let np {
                HStack(spacing: 10) {
                    artworkView(url: np.artworkURL, size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(np.title)
                            .font(.system(size: 12, weight: .medium))
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
                    control("backward.fill", action: onPrevious)
                    control(np.isPlaying ? "pause.fill" : "play.fill", action: onPlayPause)
                    control("forward.fill", action: onNext)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            } else {
                nothingPlayingView
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var nothingPlayingView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nothing playing")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))
            spotifyButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

    private func control(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
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
                }
                .buttonStyle(.plain)
                Text(np.marquee)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}
