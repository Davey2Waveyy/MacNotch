import AppKit
import SwiftUI

/// NSView subclass that initiates a proper Finder-compatible file drag.
/// SwiftUI's .draggable(URL) writes the wrong pasteboard type for cross-app
/// drags — Finder needs NSPasteboard.PasteboardType.fileURL via NSURL.
///
/// Pattern: store the mouseDown event, then start the drag on mouseDragged
/// (macOS requirement — beginDraggingSession must be called from mouseDragged).
final class FileDragSourceView: NSView, NSDraggingSource {
    var fileURL: URL?
    private var pendingMouseDown: NSEvent?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    func draggingSession(_ session: NSDraggingSession,
                         sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation { .copy }

    override func mouseDown(with event: NSEvent) {
        pendingMouseDown = event
    }

    override func mouseUp(with event: NSEvent) {
        pendingMouseDown = nil
    }

    override func mouseDragged(with event: NSEvent) {
        guard let url = fileURL, let downEvent = pendingMouseDown else { return }
        pendingMouseDown = nil
        let item = NSDraggingItem(pasteboardWriter: url as NSURL)
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        item.setDraggingFrame(CGRect(origin: .zero, size: CGSize(width: 32, height: 32)),
                              contents: icon)
        beginDraggingSession(with: [item], event: downEvent, source: self)
    }
}

/// Count badge shown in the collapsed notch bar when the shelf is non-empty.
struct ShelfCollapsedView: View {
    let count: Int

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Capsule().fill(.white.opacity(0.15)))
        }
    }
}

/// Drop-target + horizontal tray of file chips shown when expanded.
struct ShelfExpandedView: View {
    let items: [ShelfItem]
    let onDrop: ([URL]) -> Void
    let onRemove: (Int) -> Void
    let resolve: (ShelfItem) -> URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DROP SHELF")
                .font(.system(size: 9, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.4))

            if items.isEmpty {
                Text("Drop files here")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, minHeight: 28)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(items.indices, id: \.self) { index in
                            chip(items[index], index: index)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .dropDestination(for: URL.self) { urls, _ in
            onDrop(urls)
            return true
        }
    }

    @ViewBuilder
    private func chip(_ item: ShelfItem, index: Int) -> some View {
        let chipBody = HStack(spacing: 4) {
            Image(systemName: "doc.fill")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.7))
            Text(item.name)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(.white.opacity(0.10)))
        .contextMenu {
            Button("Remove", role: .destructive) { onRemove(index) }
        }

        if let resolvedURL = resolve(item) {
            chipBody.background(FileDragSourceRepresentable(url: resolvedURL))
        } else {
            chipBody
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
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Drop Shelf", systemImage: "tray.full")
            Spacer(minLength: 0)
            if items.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Drop files here")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(items.indices, id: \.self) { index in
                            chip(items[index], index: index)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .dropDestination(for: URL.self) { urls, _ in
            onDrop(urls)
            return true
        }
    }

    @ViewBuilder
    private func chip(_ item: ShelfItem, index: Int) -> some View {
        let chipBody = HStack(spacing: 4) {
            Image(systemName: "doc.fill")
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.7))
            Text(item.name)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.white.opacity(0.08)))
        .contextMenu {
            if let resolvedURL = resolve(item) {
                Button(action: {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.writeObjects([resolvedURL as NSURL])
                }) {
                    Label("Copy Path", systemImage: "doc.on.doc")
                }
                Button(action: {
                    NSWorkspace.shared.selectFile(resolvedURL.path, inFileViewerRootedAtPath: "")
                }) {
                    Label("Show in Finder", systemImage: "folder")
                }
            }
            Button("Remove", role: .destructive) { onRemove(index) }
        }

        if let resolvedURL = resolve(item) {
            chipBody.overlay(
                FileDragSourceRepresentable(url: resolvedURL)
            )
        } else {
            chipBody
        }
    }
}

/// Transparent full-size NSView placed as the chip's background so it sits
/// BELOW the SwiftUI label content in Z-order but fills the same frame,
/// receiving mouse events before SwiftUI's gesture recognisers can claim them.
struct FileDragSourceRepresentable: NSViewRepresentable {
    let url: URL
    func makeNSView(context: Context) -> FileDragSourceView {
        let v = FileDragSourceView()
        v.fileURL = url
        return v
    }
    func updateNSView(_ nsView: FileDragSourceView, context: Context) {
        nsView.fileURL = url
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
