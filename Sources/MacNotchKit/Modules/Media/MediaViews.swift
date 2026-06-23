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

/// Full now-playing card shown when the notch is expanded.
struct MediaExpandedView: View {
    let np: NowPlaying?
    let onPrevious: () -> Void
    let onPlayPause: () -> Void
    let onNext: () -> Void

    var body: some View {
        if let np {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1, green: 0.42, blue: 0.62),
                                         Color(red: 0.65, green: 0.42, blue: 1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "music.note").foregroundStyle(.white.opacity(0.85)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(np.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("\(np.artist) · \(np.app)")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 24) {
                    controlButton("backward.fill", action: onPrevious)
                    controlButton(np.isPlaying ? "pause.fill" : "play.fill", action: onPlayPause)
                    controlButton("forward.fill", action: onNext)
                }
                .frame(maxWidth: .infinity)

                if let progress = np.progress {
                    ProgressView(value: progress)
                        .tint(.white)
                        .scaleEffect(x: 1, y: 0.6, anchor: .center)
                }
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
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1, green: 0.42, blue: 0.62),
                                         Color(red: 0.65, green: 0.42, blue: 1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .overlay(Image(systemName: "music.note").foregroundStyle(.white.opacity(0.85)))
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Nothing playing")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.45))

            HStack(spacing: 8) {
                appLaunchButton("Spotify", bundleID: "com.spotify.client",
                                appPath: "/Applications/Spotify.app",
                                color: Color(red: 0.11, green: 0.73, blue: 0.33))
                appLaunchButton("Music", bundleID: "com.apple.Music",
                                appPath: "/System/Applications/Music.app",
                                color: Color(red: 1, green: 0.42, blue: 0.62))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func appLaunchButton(_ name: String, bundleID: String, appPath: String, color: Color) -> some View {
        let isRunning = NSWorkspace.shared.runningApplications
            .contains { $0.bundleIdentifier == bundleID }
        return Button {
            if isRunning {
                NSWorkspace.shared.runningApplications
                    .first { $0.bundleIdentifier == bundleID }?
                    .activate(options: .activateIgnoringOtherApps)
            } else {
                let url = URL(fileURLWithPath: appPath)
                NSWorkspace.shared.openApplication(at: url,
                    configuration: NSWorkspace.OpenConfiguration())
            }
        } label: {
            HStack(spacing: 5) {
                Circle()
                    .fill(color.opacity(0.25))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(color)
                    )
                Text(name)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
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
