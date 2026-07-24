import AppKit
import SwiftUI

struct LauncherDashboardTile: View {
    @ObservedObject var state: LauncherModule.StateBox
    let onLaunch: (PinnedApp) -> Void
    let onDrop: ([URL]) -> Void
    let onRemove: (PinnedApp) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Launcher", systemImage: "square.grid.3x3.fill")
            Spacer(minLength: 6)
            if state.apps.isEmpty {
                emptyState
            } else {
                appGrid
            }
            Spacer(minLength: 0)
            footer
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .urlDropTarget(onDrop)
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.35))
            Text("Drop .app files to pin")
                .font(.system(size: 9.5))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var appGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 34, maximum: 38), spacing: 6)], spacing: 6) {
            ForEach(state.apps) { app in
                AppIconButton(app: app, onLaunch: onLaunch, onRemove: onRemove)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down.to.line.compact").font(.system(size: 8))
            Text("Drop .app to add")
                .font(.system(size: 9))
        }
        .foregroundStyle(.white.opacity(0.35))
    }
}

struct AppIconButton: View {
    let app: PinnedApp
    let onLaunch: (PinnedApp) -> Void
    let onRemove: (PinnedApp) -> Void

    @State private var hovering = false

    var body: some View {
        Button { onLaunch(app) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hovering ? Color.white.opacity(0.10) : Color.white.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(.white.opacity(hovering ? 0.18 : 0.05), lineWidth: 0.5)
                    )
                if let img = nsIconImage(for: app.path) {
                    Image(nsImage: img)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 26, height: 26)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(width: 36, height: 36)
            .scaleEffect(hovering ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(app.name)
        .animation(.easeOut(duration: 0.12), value: hovering)
        .contextMenu {
            Button("Launch") { onLaunch(app) }
            Divider()
            Button("Unpin", role: .destructive) { onRemove(app) }
        }
    }

    private func nsIconImage(for path: String) -> NSImage? {
        let img = NSWorkspace.shared.icon(forFile: path)
        img.size = NSSize(width: 26, height: 26)
        return img
    }
}
