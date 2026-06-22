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
