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
