import SwiftUI

/// Gentle repeating scale/opacity pulse — a macOS 14-compatible stand-in for
/// the `.symbolEffect(.bounce, options: .repeating)` that needs macOS 15.
struct PulseEffect: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? 1.12 : 0.94)
            .opacity(on ? 1 : 0.7)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: on)
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
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Timers", systemImage: "timer")
            Spacer(minLength: 8)

            if let fired = firing.first {
                firingBanner(fired)
                Spacer(minLength: 0)
            } else {
                presetRow
                Spacer(minLength: 6)
                customRow
                Spacer(minLength: 6)
                runningList
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func firingBanner(_ timer: CountdownTimer) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "bell.fill")
                .font(.system(size: 18))
                .foregroundStyle(tokens.accent)
                .modifier(PulseEffect())
            Text("\(timer.label) done")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            Button { onDismiss(timer.id) } label: {
                Text("Stop")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(tokens.accent))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var presetRow: some View {
        HStack(spacing: 5) {
            ForEach(presets, id: \.label) { preset in
                Button { onStart(preset.minutes, preset.label) } label: {
                    Text(preset.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.white.opacity(0.07)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var customRow: some View {
        HStack(spacing: 6) {
            stepButton("minus") { customMinutes = max(1, customMinutes - 1) }
            Text("\(customMinutes)m")
                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
                .frame(minWidth: 28)
            stepButton("plus") { customMinutes = min(180, customMinutes + 1) }
            Button { onStart(Double(customMinutes), "\(customMinutes)m") } label: {
                Text("Start")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(tokens.accent.opacity(0.85)))
            }
            .buttonStyle(.plain)
        }
    }

    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 20, height: 20)
                .background(RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var runningList: some View {
        if active.isEmpty {
            Text("No timers running")
                .font(.system(size: 9.5))
                .foregroundStyle(.white.opacity(0.4))
        } else {
            VStack(spacing: 4) {
                ForEach(active.prefix(2)) { timer in
                    runningRow(timer)
                }
            }
        }
    }

    private func runningRow(_ timer: CountdownTimer) -> some View {
        HStack(spacing: 8) {
            Text(TimerFormat.clock(timer.remaining(at: now)))
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(tokens.accent)
            Text(timer.label)
                .font(.system(size: 9.5))
                .foregroundStyle(.white.opacity(0.65))
            Spacer(minLength: 0)
            Button(action: { onCancel(timer.id) }) {
                Text("Stop")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
            }
            .buttonStyle(.plain)
        }
    }
}
