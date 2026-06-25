import SwiftUI

// MARK: - Shared ring component

struct PomodoroRing: View {
    let progress: Double
    let phase: PomodoroPhase
    let remaining: TimeInterval
    let isRunning: Bool
    var ringSize: CGFloat = 80
    var strokeWidth: CGFloat = 6

    private var phaseColor: Color {
        switch phase {
        case .focus: return Color(red: 1, green: 0.35, blue: 0.35)
        case .shortBreak: return Color(red: 0.35, green: 0.9, blue: 0.55)
        case .longBreak: return Color(red: 0.35, green: 0.65, blue: 1)
        }
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: strokeWidth)
                .frame(width: ringSize, height: ringSize)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    phaseColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: ringSize, height: ringSize)
                .animation(.linear(duration: 0.5), value: progress)

            // Center time
            VStack(spacing: 1) {
                Text(formatTime(remaining))
                    .font(.system(size: ringSize * 0.19, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                Text(phase.label)
                    .font(.system(size: ringSize * 0.09, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .tracking(0.4)
            }
        }
        .scaleEffect(isRunning ? 1.0 : 0.97)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isRunning)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let total = Int(ceil(t))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}

// Session dots: filled = completed this cycle, outlined = remaining
private struct SessionDots: View {
    let completed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < completed ? Color.white.opacity(0.8) : Color.white.opacity(0.2))
                    .frame(width: 5, height: 5)
            }
        }
    }
}

// MARK: - Collapsed indicator

public struct PomodoroCollapsedView: View {
    @ObservedObject var store: PomodoroStore

    public var body: some View {
        if store.isRunning || store.elapsed > 0 {
            HStack(spacing: 4) {
                Circle()
                    .fill(store.phase == .focus ? Color(red: 1, green: 0.4, blue: 0.4) : Color(red: 0.4, green: 0.9, blue: 0.5))
                    .frame(width: 5, height: 5)
                    .opacity(store.isRunning ? 1 : 0.4)
                Text(formatShort(store.remaining))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
    }

    private func formatShort(_ t: TimeInterval) -> String {
        let total = Int(ceil(t))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Compact expanded view (hover panel)

public struct PomodoroExpandedView: View {
    @ObservedObject var store: PomodoroStore
    @State private var showDistractionInput = false
    @State private var distractionText = ""

    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                PomodoroRing(
                    progress: store.progress,
                    phase: store.phase,
                    remaining: store.remaining,
                    isRunning: store.isRunning,
                    ringSize: 80,
                    strokeWidth: 6
                )

                VStack(alignment: .leading, spacing: 10) {
                    SessionDots(
                        completed: store.sessionInCycle - 1,
                        total: store.sessionsBeforeLongBreak
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        controlButton(
                            icon: store.isRunning ? "pause.fill" : "play.fill",
                            label: store.isRunning ? "Pause" : "Start",
                            primary: true
                        ) { store.toggle() }

                        HStack(spacing: 8) {
                            controlButton(icon: "arrow.counterclockwise", label: "Reset", primary: false) {
                                store.reset()
                            }
                            controlButton(icon: "forward.fill", label: "Skip", primary: false) {
                                store.skip()
                            }
                        }
                    }
                }
            }

            if showDistractionInput {
                HStack(spacing: 6) {
                    TextField("What pulled you away?", text: $distractionText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                        .onSubmit {
                            store.logDistraction(distractionText)
                            distractionText = ""
                            showDistractionInput = false
                        }
                    Button {
                        showDistractionInput = false
                        distractionText = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 7).fill(.white.opacity(0.07)))
            } else if store.isRunning {
                Button {
                    showDistractionInput = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.bubble")
                            .font(.system(size: 10))
                        Text("Log distraction")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func controlButton(icon: String, label: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: primary ? 12 : 10, weight: primary ? .semibold : .medium))
                Text(label)
                    .font(.system(size: primary ? 12 : 10, weight: primary ? .semibold : .medium))
            }
            .foregroundStyle(primary ? .white : .white.opacity(0.55))
            .padding(.horizontal, primary ? 12 : 9)
            .padding(.vertical, primary ? 7 : 5)
            .fixedSize()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(primary ? Color.white.opacity(0.15) : Color.white.opacity(0.07))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dashboard tile

public struct PomodoroDashboardTile: View {
    @ObservedObject var store: PomodoroStore
    @State private var showDistractionInput = false
    @State private var distractionText = ""

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top: ring + stats side by side
            HStack(spacing: 14) {
                PomodoroRing(
                    progress: store.progress,
                    phase: store.phase,
                    remaining: store.remaining,
                    isRunning: store.isRunning,
                    ringSize: 86,
                    strokeWidth: 7
                )

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 5) {
                        SessionDots(
                            completed: store.sessionInCycle - 1,
                            total: store.sessionsBeforeLongBreak
                        )
                        Text("Session \(store.sessionInCycle)/\(store.sessionsBeforeLongBreak)")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.40))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.45))
                        Text("\(store.completedSessions) done today")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.50))
                    }
                }
                Spacer(minLength: 0)
            }

            // Bottom: full-width controls + distraction
            HStack(spacing: 8) {
                // Play/Pause — stretches to fill available space
                Button(action: store.toggle) {
                    HStack(spacing: 6) {
                        Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(store.isRunning ? "Pause" : "Start")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.white.opacity(0.14)))
                }
                .buttonStyle(.plain)

                iconBtn("arrow.counterclockwise", action: store.reset)
                iconBtn("forward.fill", action: store.skip)

                if showDistractionInput {
                    HStack(spacing: 5) {
                        TextField("Distraction…", text: $distractionText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundStyle(.white)
                            .onSubmit {
                                store.logDistraction(distractionText)
                                distractionText = ""
                                showDistractionInput = false
                            }
                        Button { showDistractionInput = false; distractionText = "" } label: {
                            Image(systemName: "xmark").font(.system(size: 9)).foregroundStyle(.white.opacity(0.4))
                        }.buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 7).fill(.white.opacity(0.07)))
                } else {
                    Button {
                        if store.isRunning { showDistractionInput = true }
                    } label: {
                        Image(systemName: "exclamationmark.bubble")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(store.isRunning ? 0.45 : 0.20))
                            .padding(7)
                            .background(RoundedRectangle(cornerRadius: 7).fill(.white.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.isRunning)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func iconBtn(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.50))
                .padding(7)
                .background(RoundedRectangle(cornerRadius: 7).fill(.white.opacity(0.07)))
        }
        .buttonStyle(.plain)
    }
}
