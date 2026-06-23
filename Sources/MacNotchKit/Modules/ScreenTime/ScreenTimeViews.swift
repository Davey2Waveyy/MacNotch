import SwiftUI

/// Palette for the donut segments / legend dots. Ordered so the busiest apps
/// get the most distinct colors.
enum ScreenTimePalette {
    static let colors: [Color] = [
        Color(red: 0.36, green: 0.78, blue: 1.00),   // blue
        Color(red: 0.62, green: 0.55, blue: 1.00),   // purple
        Color(red: 0.27, green: 0.85, blue: 0.62),   // green
        Color(red: 1.00, green: 0.62, blue: 0.42),   // orange
        Color(red: 1.00, green: 0.42, blue: 0.62),   // pink
    ]
    static let rest = Color.white.opacity(0.14)

    static func color(_ index: Int) -> Color {
        index < colors.count ? colors[index] : rest
    }
}

struct ScreenTimeDashboardTile: View {
    let ranked: [AppUsage]
    let total: TimeInterval
    let switches: Int

    private var topApps: [AppUsage] { Array(ranked.prefix(4)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                TileHeader(title: "Screen Time", systemImage: "hourglass")
                if switches > 0 {
                    Text("\(switches) switches")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            Spacer(minLength: 8)
            if ranked.isEmpty {
                emptyState
            } else {
                content
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var emptyState: some View {
        Text("Tracking starts now…")
            .font(.system(size: 10))
            .foregroundStyle(.white.opacity(0.4))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var content: some View {
        HStack(spacing: 12) {
            DonutChart(segments: segments, centerText: ScreenTimeFormat.duration(total), centerCaption: "today")
                .frame(width: 76, height: 76)
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(topApps.enumerated()), id: \.element.id) { index, app in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ScreenTimePalette.color(index))
                            .frame(width: 6, height: 6)
                        Text(app.name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(ScreenTimeFormat.short(app.seconds))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.55))
                            .monospacedDigit()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var segments: [DonutSegment] {
        guard total > 0 else { return [] }
        var result: [DonutSegment] = []
        for (index, app) in topApps.enumerated() {
            result.append(DonutSegment(value: app.seconds, color: ScreenTimePalette.color(index)))
        }
        let accounted = topApps.reduce(0) { $0 + $1.seconds }
        if total - accounted > 1 {
            result.append(DonutSegment(value: total - accounted, color: ScreenTimePalette.rest))
        }
        return result
    }
}

struct DonutSegment {
    let value: Double
    let color: Color
}

/// A ring chart with a centered label. Segments are drawn as trimmed strokes
/// around a circle, proportional to their values.
struct DonutChart: View {
    let segments: [DonutSegment]
    let centerText: String
    let centerCaption: String

    private var total: Double { max(segments.reduce(0) { $0 + $1.value }, 0.0001) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 9)

            ForEach(Array(boundaries.enumerated()), id: \.offset) { _, b in
                Circle()
                    .trim(from: b.start, to: b.end)
                    .stroke(b.color, style: StrokeStyle(lineWidth: 9, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 0) {
                Text(centerText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(centerCaption)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 6)
        }
    }

    private var boundaries: [(start: CGFloat, end: CGFloat, color: Color)] {
        var result: [(CGFloat, CGFloat, Color)] = []
        var cursor: CGFloat = 0
        let gap: CGFloat = segments.count > 1 ? 0.012 : 0
        for segment in segments {
            let fraction = CGFloat(segment.value / total)
            let start = cursor
            let end = cursor + fraction
            let drawnEnd = max(start, end - gap)
            result.append((start, drawnEnd, segment.color))
            cursor = end
        }
        return result
    }
}
