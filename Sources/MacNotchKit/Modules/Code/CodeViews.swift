import SwiftUI

/// A pinned project plus its latest git status, for display.
struct CodeProjectDisplay: Equatable, Sendable {
    var name: String
    var status: GitStatus
}

struct CodeExpandedView: View {
    let projects: [CodeProjectDisplay]
    let onAction: (Int, CodeAction) -> Void
    let onRemove: (Int) -> Void
    let onDrop: ([URL]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CODE")
                .font(.system(size: 9, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.4))

            if projects.isEmpty {
                Text("Drop a project folder here")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, minHeight: 28)
            } else {
                ForEach(projects.indices, id: \.self) { index in
                    row(projects[index], index: index)
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

    private func row(_ project: CodeProjectDisplay, index: Int) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                statusLine(project.status)
            }
            Spacer(minLength: 4)
            actionButton("sparkles", help: "Launch Claude Code") { onAction(index, .claudeCode) }
            actionButton("chevron.left.forwardslash.chevron.right", help: "Open in editor") { onAction(index, .editor) }
            actionButton("terminal", help: "Open Terminal") { onAction(index, .terminal) }
        }
        .padding(.vertical, 3)
        .contextMenu {
            Button("Reveal in Finder") { onAction(index, .reveal) }
            Button("Remove", role: .destructive) { onRemove(index) }
        }
    }

    @ViewBuilder
    private func statusLine(_ status: GitStatus) -> some View {
        HStack(spacing: 5) {
            if let branch = status.branch {
                Text(branch)
                    .foregroundStyle(.white.opacity(0.6))
                if status.isDirty {
                    Circle().fill(Color(red: 1, green: 0.72, blue: 0.2)).frame(width: 5, height: 5)
                }
                if status.ahead > 0 {
                    Text("↑\(status.ahead)").foregroundStyle(.white.opacity(0.5))
                }
                if status.behind > 0 {
                    Text("↓\(status.behind)").foregroundStyle(.white.opacity(0.5))
                }
            } else {
                Text("no repo").foregroundStyle(.white.opacity(0.35))
            }
        }
        .font(.system(size: 9))
    }

    private func actionButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

/// Pinned-projects widget for the dashboard layout.
struct CodeDashboardTile: View {
    let projects: [CodeProjectDisplay]
    let onAction: (Int, CodeAction) -> Void
    let onRemove: (Int) -> Void
    let onDrop: ([URL]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TileHeader(title: "Code", systemImage: "chevron.left.forwardslash.chevron.right")
            Spacer(minLength: 0)
            if projects.isEmpty {
                Text("Drop a project folder here")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(projects.indices, id: \.self) { index in
                            row(projects[index], index: index)
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

    private func row(_ project: CodeProjectDisplay, index: Int) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(project.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    if let branch = project.status.branch {
                        Text(branch).foregroundStyle(.white.opacity(0.6))
                        if project.status.isDirty {
                            Circle().fill(Color(red: 1, green: 0.72, blue: 0.2)).frame(width: 5, height: 5)
                        }
                    } else {
                        Text("no repo").foregroundStyle(.white.opacity(0.35))
                    }
                }
                .font(.system(size: 9))
            }
            Spacer(minLength: 4)
            actionButton("sparkles", help: "Launch Claude Code") { onAction(index, .claudeCode) }
            actionButton("terminal", help: "Open Terminal") { onAction(index, .terminal) }
        }
        .contextMenu {
            Button("Reveal in Finder") { onAction(index, .reveal) }
            Button("Remove", role: .destructive) { onRemove(index) }
        }
    }

    private func actionButton(_ systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

/// First-project summary for the wide bar.
struct CodeWideBar: View {
    let projects: [CodeProjectDisplay]

    var body: some View {
        if let first = projects.first {
            WideBarItem(systemImage: "chevron.left.forwardslash.chevron.right",
                        text: first.status.branch.map { "\(first.name) · \($0)" } ?? first.name) {
                if first.status.isDirty {
                    Circle().fill(Color(red: 1, green: 0.72, blue: 0.2)).frame(width: 5, height: 5)
                }
            }
        }
    }
}
