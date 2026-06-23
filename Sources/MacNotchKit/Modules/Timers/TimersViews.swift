import SwiftUI

struct TimersDashboardTile: View {
    let active: [CountdownTimer]
    let now: Date
    let justFired: String?
    let onStart: (Double, String) -> Void
    let onCancel: (UUID) -> Void

    private let presets: [(label: String, minutes: Double)] = [
        ("5m", 5), ("15m", 15), ("25m", 25)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Timers", systemImage: "timer")
            Spacer(minLength: 8)

            if let justFired {
                HStack(spacing: 5) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(NotchTheme.accent)
                    Text("\(justFired) done")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                }
                .padding(.bottom, 4)
            }

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

            Spacer(minLength: 6)

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
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func runningRow(_ timer: CountdownTimer) -> some View {
        HStack(spacing: 6) {
            Text(TimerFormat.clock(timer.remaining(at: now)))
                .font(.system(size: 12, weight: .semibold).monospacedDigit())
                .foregroundStyle(NotchTheme.accent)
            Text(timer.label)
                .font(.system(size: 9.5))
                .foregroundStyle(.white.opacity(0.5))
            Spacer(minLength: 2)
            Button { onCancel(timer.id) } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.35))
            }
            .buttonStyle(.plain)
        }
    }
}
