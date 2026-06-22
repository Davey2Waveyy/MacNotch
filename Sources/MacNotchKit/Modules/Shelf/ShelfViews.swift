import SwiftUI

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
            chipBody.draggable(resolvedURL)
        } else {
            chipBody
        }
    }
}
