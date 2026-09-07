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

/// Agenda widget for the dashboard layout.
struct CalendarDashboardTile: View {
    let events: [CalEvent]
    let accessDenied: Bool
    let onGrantAccess: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Calendar", systemImage: "calendar")
            Text(CalendarFormat.dayHeader(Date(), calendar: .current))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.top, 4)
            Spacer(minLength: 0)
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
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(events.prefix(3).indices, id: \.self) { index in
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
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Next-event summary for the wide bar.
struct CalendarWideBar: View {
    let events: [CalEvent]
    let accessDenied: Bool

    var body: some View {
        if accessDenied {
            WideBarItem(systemImage: "calendar.badge.exclamationmark", text: "Calendar off")
        } else if let next = events.first {
            WideBarItem(systemImage: "calendar",
                        text: "\(CalendarFormat.timeLabel(next.start, calendar: .current))  \(next.title)")
        } else {
            WideBarItem(systemImage: "calendar", text: "No more today")
        }
    }
}
