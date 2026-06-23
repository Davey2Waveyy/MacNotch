import SwiftUI

struct RemindersDashboardTile: View {
    let reminders: [Reminder]
    let onAdd: (String) -> Void
    let onToggle: (UUID) -> Void
    let onRemove: (UUID) -> Void
    let onClearDone: () -> Void

    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    private var active: [Reminder] { reminders.filter { !$0.isDone } }
    private var done: [Reminder] { reminders.filter { $0.isDone } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                TileHeader(title: "Reminders", systemImage: "checklist")
                Spacer(minLength: 0)
                if !done.isEmpty {
                    Button("Clear done") { onClearDone() }
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 6)

            // Input row
            HStack(spacing: 6) {
                TextField("Add reminder…", text: $draft)
                    .font(.system(size: 10))
                    .foregroundStyle(.white)
                    .textFieldStyle(.plain)
                    .focused($inputFocused)
                    .onSubmit { submit() }

                if !draft.isEmpty {
                    Button { submit() } label: {
                        Image(systemName: "return")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(NotchTheme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(inputFocused ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(inputFocused ? NotchTheme.accent.opacity(0.5) : Color.white.opacity(0.07), lineWidth: 0.75)
                    )
            )
            .animation(.easeOut(duration: 0.12), value: inputFocused)

            Spacer(minLength: 5)

            if reminders.isEmpty {
                Text("Nothing here yet")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 3) {
                    ForEach(active.prefix(4)) { reminder in
                        ReminderRow(reminder: reminder, onToggle: onToggle, onRemove: onRemove)
                    }
                    ForEach(done.prefix(2)) { reminder in
                        ReminderRow(reminder: reminder, onToggle: onToggle, onRemove: onRemove)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func submit() {
        guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onAdd(draft)
        draft = ""
        inputFocused = false
    }
}

private struct ReminderRow: View {
    let reminder: Reminder
    let onToggle: (UUID) -> Void
    let onRemove: (UUID) -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 7) {
            Button { onToggle(reminder.id) } label: {
                Image(systemName: reminder.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(reminder.isDone ? NotchTheme.accent.opacity(0.7) : .white.opacity(0.5))
            }
            .buttonStyle(.plain)

            Text(reminder.title)
                .font(.system(size: 9.5))
                .foregroundStyle(reminder.isDone ? .white.opacity(0.3) : .white.opacity(0.85))
                .strikethrough(reminder.isDone, color: .white.opacity(0.3))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if hovering {
                Button { onRemove(reminder.id) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(hovering ? Color.white.opacity(0.06) : Color.clear)
        )
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.1), value: hovering)
    }
}
