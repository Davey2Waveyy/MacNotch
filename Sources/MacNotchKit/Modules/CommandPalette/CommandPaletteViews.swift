import SwiftUI

struct CommandPaletteTile: View {
    @ObservedObject var model: CommandPaletteModel
    @State private var query = ""

    var body: some View {
        let results = model.filteredCommands(query: query)
        VStack(alignment: .leading, spacing: 8) {
            TileHeader(title: "Command Palette", systemImage: "command")
            TextField("Search commands", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.08)))
                .accessibilityLabel("Search commands")
            if results.isEmpty && !query.isEmpty {
                Text("No matching commands")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .accessibilityLabel("No matching commands")
            } else {
                ScrollView(showsIndicators: false) {
                    let rowSpacing: CGFloat = 4
                    VStack(alignment: .leading, spacing: rowSpacing) {
                        ForEach(results, id: \.id) { command in
                            Button(command.title) { command.action() }
                                .buttonStyle(.plain)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.86))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                // Self-limiting inset: widens the tap target without
                                // reaching past the midpoint of the row spacing, so
                                // adjacent rows' hit areas never overlap.
                                .contentShape(Rectangle().inset(by: -rowSpacing / 2))
                                .accessibilityLabel(command.title)
                        }
                    }
                }
            }
        }
        .padding(12)
    }
}
