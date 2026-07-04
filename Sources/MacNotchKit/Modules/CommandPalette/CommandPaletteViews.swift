import SwiftUI

struct CommandPaletteTile: View {
    @Environment(\.notchTokens) private var tokens
    @ObservedObject var model: CommandPaletteModel
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        let results = model.filteredCommands(query: query)
        VStack(alignment: .leading, spacing: 8) {
            TileHeader(title: "Command Palette", systemImage: "command")

            // Search field (mirrors the Reminders input treatment)
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(searchFocused ? tokens.accent : .white.opacity(0.45))
                TextField("Search commands", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .focused($searchFocused)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(searchFocused ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(searchFocused ? tokens.accent.opacity(0.5) : Color.white.opacity(0.07), lineWidth: 0.75)
                    )
            )
            .animation(.easeOut(duration: 0.12), value: searchFocused)
            .accessibilityLabel("Search commands")

            if results.isEmpty && !query.isEmpty {
                ModuleEmptyStateView(
                    title: "No Matching Commands",
                    message: "Try a different search term.",
                    systemImage: "magnifyingglass"
                )
            } else {
                ScrollView(showsIndicators: false) {
                    let rowSpacing: CGFloat = 4
                    VStack(alignment: .leading, spacing: rowSpacing) {
                        ForEach(results, id: \.id) { command in
                            CommandPaletteRow(command: command, rowSpacing: rowSpacing)
                        }
                    }
                }
            }
        }
        .padding(12)
    }
}

/// One command result row: leading icon + title + hover-reveal return hint,
/// styled to match ReminderRow in RemindersViews.swift.
private struct CommandPaletteRow: View {
    let command: CommandPaletteCommand
    let rowSpacing: CGFloat

    @State private var hovering = false

    var body: some View {
        Button { command.action() } label: {
            HStack(spacing: 7) {
                Image(systemName: Self.icon(for: command.id))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 14)

                Text(command.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.86))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if hovering {
                    Image(systemName: "return")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(hovering ? Color.white.opacity(0.06) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        // Self-limiting inset: widens the tap target without reaching past
        // the midpoint of the row spacing, so adjacent rows' hit areas
        // never overlap.
        .contentShape(Rectangle().inset(by: -rowSpacing / 2))
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.1), value: hovering)
        .accessibilityLabel(command.title)
    }

    // ponytail: id-based lookup instead of a new model field — avoids touching
    // tested public API; add a systemImage field if commands grow icon needs.
    private static func icon(for id: String) -> String {
        if id.hasPrefix("workspace-") { return "rectangle.stack" }
        switch id {
        case "open-settings": return "gearshape"
        case "toggle-notch": return "macwindow"
        default: return "command"
        }
    }
}
