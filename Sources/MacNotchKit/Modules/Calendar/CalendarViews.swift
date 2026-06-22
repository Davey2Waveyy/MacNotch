import SwiftUI

struct CalendarExpandedView: View {
    let events: [CalEvent]
    let accessDenied: Bool
    let onGrantAccess: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(CalendarFormat.dayHeader(Date(), calendar: .current))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)

            if accessDenied {
                Button(action: onGrantAccess) {
                    Text("Grant Calendar access")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 0.35, green: 0.78, blue: 1))
                }
                .buttonStyle(.plain)
            } else if events.isEmpty {
                Text("Nothing left today")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(events.indices, id: \.self) { index in
                    let event = events[index]
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.35, green: 0.78, blue: 1))
                            .frame(width: 5, height: 5)
                        Text(CalendarFormat.timeLabel(event.start, calendar: .current))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(event.title)
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    .font(.system(size: 10))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
