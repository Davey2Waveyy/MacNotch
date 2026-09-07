import SwiftUI

struct ClipboardDashboardTile: View {
    let entries: [ClipboardEntry]
    let onRemove: (UUID) -> Void
    let onCopy: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Clipboard", systemImage: "doc.on.clipboard")
            Spacer(minLength: 6)
            if entries.isEmpty {
                Text("Nothing copied yet")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 3) {
                    ForEach(entries.prefix(6)) { entry in
                        ClipboardRow(entry: entry, onCopy: onCopy, onRemove: onRemove)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct ClipboardRow: View {
    let entry: ClipboardEntry
    let onCopy: (String) -> Void
    let onRemove: (UUID) -> Void

    @State private var hovering = false
    @State private var justCopied = false

    var body: some View {
        HStack(spacing: 6) {
            Text(entry.text)
                .font(.system(size: 9.5))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if hovering {
                Button {
                    onCopy(entry.text)
                    justCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { justCopied = false }
                } label: {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(justCopied ? .green : .white.opacity(0.6))
                }
                .buttonStyle(.plain)

                Button { onRemove(entry.id) } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(hovering ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        )
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.1), value: hovering)
        .animation(.easeOut(duration: 0.12), value: justCopied)
    }
}
