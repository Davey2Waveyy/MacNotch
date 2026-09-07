import SwiftUI

/// Gentle repeating scale/opacity pulse — a macOS 14-compatible stand-in for
/// the `.symbolEffect(.bounce, options: .repeating)` that needs macOS 15.
/// Stays static when the resolved theme motion is reduced.
struct PulseEffect: ViewModifier {
    @Environment(\.notchTokens) private var tokens
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? 1.12 : 0.94)
            .opacity(on ? 1 : 0.7)
            .animation(
                tokens.motionStyle == .reduced
                    ? nil
                    : .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                value: on
            )
            .onAppear { on = true }
    }
}

struct TimersDashboardTile: View {
    @Environment(\.notchTokens) private var tokens
    let active: [CountdownTimer]
    let now: Date
    let firing: [CountdownTimer]
    let onStart: (Double, String) -> Void
    let onCancel: (UUID) -> Void
    let onDismiss: (UUID) -> Void

    @State private var customMinutes: Int = 10

    private let presets: [(label: String, minutes: Double)] = [
        ("5m", 5), ("15m", 15), ("25m", 25)
    ]

    var body: some View {
        NotchTile("Timers", systemImage: "timer") {
            if let fired = firing.first {
                firingBanner(fired)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    presetRow
                    customRow
                    runningList
                        .frame(maxHeight: .infinity)
                }
            }
        } trailing: {
            if !active.isEmpty {
                Text("\(active.count) RUNNING")
            }
        }
    }

    private func firingBanner(_ timer: CountdownTimer) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .font(.system(size: 18))
                .foregroundStyle(tokens.accent)
                .modifier(PulseEffect())
            Text("\(timer.label) done")
                .font(tokens.titleFont)
                .foregroundStyle(tokens.textPrimary)
            Button("Stop") { onDismiss(timer.id) }
                .buttonStyle(.notchPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var presetRow: some View {
        HStack(spacing: 6) {
            ForEach(presets, id: \.label) { preset in
                Button { onStart(preset.minutes, preset.label) } label: {
                    Text(preset.label).frame(maxWidth: .infinity)
                }
                .buttonStyle(.notchSoft)
            }
        }
    }

    private var customRow: some View {
        HStack(spacing: 6) {
            NotchIconButton(systemName: "minus", accessibilityLabel: "Decrease minutes",
                            size: 24, iconSize: 9) {
                customMinutes = max(1, customMinutes - 1)
            }
            Text("\(customMinutes)m")
                .font(tokens.labelFont.weight(.semibold).monospacedDigit())
                .foregroundStyle(tokens.textPrimary)
                .contentTransition(.numericText(value: Double(customMinutes)))
                .animation(tokens.pressAnimation, value: customMinutes)
                .frame(minWidth: 30)
            NotchIconButton(systemName: "plus", accessibilityLabel: "Increase minutes",
                            size: 24, iconSize: 9) {
                customMinutes = min(180, customMinutes + 1)
            }
            Button { onStart(Double(customMinutes), "\(customMinutes)m") } label: {
                Label("Start", systemImage: "play.fill").frame(width: 60)
            }
            .buttonStyle(.notchPrimary)
        }
    }

    @ViewBuilder
    private var runningList: some View {
        if active.isEmpty {
            VStack(spacing: 8) {
                Text(String(format: "%02d:00", customMinutes))
                    .font(.system(size: 38, weight: .light, design: .rounded).monospacedDigit())
                    .foregroundStyle(tokens.textPrimary)
                    .contentTransition(.numericText())
                Text("A moment for what matters.")
                    .font(tokens.bodyFont).foregroundStyle(tokens.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 4) {
                ForEach(active.prefix(2)) { timer in
                    runningRow(timer)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func runningRow(_ timer: CountdownTimer) -> some View {
        let remaining = timer.remaining(at: now)
        return HStack(spacing: 8) {
            Text(TimerFormat.clock(remaining))
                .font(tokens.displayFont)
                .foregroundStyle(tokens.accent)
                .contentTransition(.numericText(countsDown: true))
                .animation(.linear(duration: 0.3), value: remaining)
            Text(timer.label)
                .font(tokens.captionFont)
                .foregroundStyle(tokens.textTertiary)
            Spacer(minLength: 0)
            Button("Stop") { onCancel(timer.id) }
                .buttonStyle(.notchGhost)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous)
                .fill(.white.opacity(0.04))
        )
    }
}
