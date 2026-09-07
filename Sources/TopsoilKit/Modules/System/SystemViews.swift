import SwiftUI

struct SystemExpandedView: View {
    let sample: SystemSample

    var body: some View {
        HStack(spacing: 10) {
            Label(sample.batteryLabel, systemImage: "battery.100")
                .foregroundStyle(.white)

            Spacer(minLength: 8)

            Text("CPU \(sample.cpuLabel)  RAM \(sample.ramLabel)")
                .foregroundStyle(.white.opacity(0.7))
        }
        .font(.system(size: 11, weight: .medium))
    }
}

/// Battery-forward widget for the dashboard layout.
struct SystemDashboardTile: View {
    let sample: SystemSample

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Battery & System", systemImage: "bolt.heart")
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(sample.batteryPercent.map(String.init) ?? "—")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                if sample.batteryPercent != nil {
                    Text("%")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                if sample.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(red: 1, green: 0.82, blue: 0.2))
                }
            }
            HStack(spacing: 12) {
                metric("CPU", sample.cpuLabel)
                metric("RAM", sample.ramLabel)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
    }
}

/// Inline battery/CPU/RAM status for the wide bar.
struct SystemWideBar: View {
    let sample: SystemSample

    var body: some View {
        HStack(spacing: 14) {
            WideBarItem(systemImage: sample.isCharging ? "battery.100.bolt" : "battery.100",
                        text: sample.batteryLabel)
            WideBarItem(systemImage: "cpu", text: sample.cpuLabel)
            WideBarItem(systemImage: "memorychip", text: sample.ramLabel)
        }
    }
}
