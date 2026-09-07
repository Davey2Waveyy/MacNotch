import AppKit
import SwiftUI

/// Count badge shown in the collapsed notch bar when the shelf is non-empty.
struct ShelfCollapsedView: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Capsule().fill(.white.opacity(0.15)))
                .contentTransition(.numericText())
        }
    }
}

/// Drop-target + horizontal tray of file chips shown when expanded.
struct ShelfExpandedView: View {
    @Environment(\.notchTokens) private var tokens
    let items: [ShelfItem]
    let onDrop: ([URL]) -> Void
    let onRemove: (Int) -> Void
    let resolve: (ShelfItem) -> URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Text("DROP SHELF")
                    .font(tokens.caption2Font)
                    .tracking(0.9)
                    .foregroundStyle(tokens.textTertiary)
                Spacer(minLength: 0)
                if !items.isEmpty {
                    Text("\(items.count)")
                        .font(tokens.caption2Font)
                        .foregroundStyle(tokens.textQuaternary)
                }
            }

            if items.isEmpty {
                ShelfDropZone(compact: true)
            } else {
                // No ScrollView — it intercepts drag gestures before .onDrag fires.
                // Cap the row so a full shelf can't overflow the panel; the rest
                // is reachable from the dashboard tile.
                let visibleCount = min(items.count, 4)
                HStack(spacing: 6) {
                    ForEach(0..<visibleCount, id: \.self) { index in
                        ShelfChip(item: items[index],
                                  resolve: resolve,
                                  onRemove: { onRemove(index) })
                    }
                    if items.count > visibleCount {
                        Text("+\(items.count - visibleCount)")
                            .font(tokens.captionFont)
                            .foregroundStyle(tokens.textTertiary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous)
                                    .strokeBorder(.white.opacity(0.10), lineWidth: 0.75)
                            )
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .urlDropTarget(onDrop)
    }
}

/// Dashed outline that shows exactly where files land.
private struct ShelfDropZone: View {
    @Environment(\.notchTokens) private var tokens
    var compact = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: compact ? 10 : 12, weight: .medium))
                .foregroundStyle(tokens.textTertiary)
            Text("Drop files here")
                .font(compact ? tokens.captionFont : tokens.bodyFont)
                .foregroundStyle(tokens.textTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 30 : 44, maxHeight: compact ? nil : .infinity)
        .background(
            RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.14),
                              style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        )
    }
}

/// One shelf file: draggable chip with hover feedback and a context menu.
private struct ShelfChip: View {
    @Environment(\.notchTokens) private var tokens
    let item: ShelfItem
    let resolve: (ShelfItem) -> URL?
    let onRemove: () -> Void
    var showsFinderActions = false

    @State private var hovering = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: tokens.controlCornerRadius, style: .continuous)
        let chipBody = HStack(spacing: 5) {
            Image(systemName: "doc.fill")
                .font(.system(size: 9))
                .foregroundStyle(hovering ? tokens.accent : tokens.textTertiary)
            Text(item.name)
                .font(tokens.captionFont)
                .foregroundStyle(hovering ? tokens.textPrimary : tokens.textSecondary)
                .lineLimit(1)
            if showsFinderActions { Spacer(minLength: 0) }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(shape.fill(.white.opacity(hovering ? 0.11 : 0.06)))
        .overlay(shape.strokeBorder(.white.opacity(hovering ? 0.18 : 0.09), lineWidth: 0.75))
        .animation(tokens.hoverAnimation, value: hovering)
        .onHover { hovering = $0 }
        .contextMenu {
            if showsFinderActions, let resolvedURL = resolve(item) {
                Button {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.writeObjects([resolvedURL as NSURL])
                } label: {
                    Label("Copy Path", systemImage: "doc.on.doc")
                }
                Button {
                    NSWorkspace.shared.selectFile(resolvedURL.path, inFileViewerRootedAtPath: "")
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
            }
            Button("Remove", role: .destructive, action: onRemove)
        }

        if let resolvedURL = resolve(item) {
            chipBody.urlDragSource(resolvedURL)
        } else {
            // Bookmark no longer resolves — tell VoiceOver the file is stale.
            chipBody.accessibilityLabel("\(item.name), file unavailable")
        }
    }
}

/// Drop-shelf widget for the dashboard layout (same drop target, tile framing).
struct ShelfDashboardTile: View {
    let items: [ShelfItem]
    let onDrop: ([URL]) -> Void
    let onRemove: (Int) -> Void
    let resolve: (ShelfItem) -> URL?

    var body: some View {
        NotchTile("Drop Shelf", systemImage: "tray.full") {
            if items.isEmpty {
                ShelfDropZone()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(items.indices, id: \.self) { index in
                            ShelfChip(item: items[index],
                                      resolve: resolve,
                                      onRemove: { onRemove(index) },
                                      showsFinderActions: true)
                        }
                    }
                }
            }
        } trailing: {
            if !items.isEmpty {
                Text("\(items.count) FILE\(items.count == 1 ? "" : "S")")
            }
        }
        .contentShape(Rectangle())
        .urlDropTarget(onDrop)
    }
}

/// Item-count summary for the wide bar.
struct ShelfWideBar: View {
    let count: Int

    var body: some View {
        WideBarItem(systemImage: "tray.full",
                    text: count == 0 ? "Shelf empty" : "\(count) file\(count == 1 ? "" : "s")")
    }
}
