import AppKit
import SwiftUI

// MARK: - Model

struct CodeProjectDisplay: Equatable, Sendable {
    var name: String
    var status: GitStatus
}

private func accent(for tool: CodeCLITool) -> Color {
    switch tool {
    case .claude: return Color(red: 0.78, green: 0.52, blue: 1.00)
    case .codex: return Color(red: 0.36, green: 0.78, blue: 1.00)
    case .cursor: return Color(red: 0.27, green: 0.98, blue: 0.72)
    }
}

// MARK: - Compact expanded view

struct CodeExpandedView: View {
    let projects: [CodeProjectDisplay]
    let onAction: (Int, CodeAction) -> Void
    let onRemove: (Int) -> Void
    let onDrop: ([URL]) -> Void
    var onLaunchCLI: ((CodeCLITool) -> Void)? = nil

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("CODE")
                .font(.system(size: 9, weight: .medium))
                .tracking(0.5)
                .foregroundStyle(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .leading)

            if projects.isEmpty {
                emptyProject
                cliQuickLaunch
            } else {
                ForEach(projects.indices, id: \.self) { index in
                    row(projects[index], index: index)
                }
                cliQuickLaunch
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .contentShape(Rectangle())
        .dropDestination(for: URL.self) { urls, _ in
            onDrop(urls)
            return true
        }
    }

    // Always-visible CLI quick-launch row so the tile is never empty.
    @ViewBuilder
    private var cliQuickLaunch: some View {
        HStack(spacing: 7) {
            ForEach(CodeTerminalPaneDescriptor.defaultPanes) { pane in
                cliChip(pane)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func cliChip(_ pane: CodeTerminalPaneDescriptor) -> some View {
        Button { onLaunchCLI?(pane.tool) } label: {
            HStack(spacing: 5) {
                CodeToolIcon(tool: pane.tool, size: 13)
                Text(pane.command)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .frame(minWidth: 64)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.black.opacity(0.26))
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(accent(for: pane.tool).opacity(0.28), lineWidth: 0.5))
            )
        }
        .buttonStyle(.plain)
        .help("Open \(pane.displayName) in notch")
    }

    private var emptyProject: some View {
        VStack(spacing: 2) {
            Text("No folder pinned")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
            Text("drop a folder")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.32))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }

    private func row(_ project: CodeProjectDisplay, index: Int) -> some View {
        VStack(spacing: 7) {
            VStack(alignment: .center, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                statusLine(project.status)
            }

            HStack(spacing: 16) {
                actionButton("sparkles", help: "Launch Claude Code") { onAction(index, .claudeCode) }
                actionButton("chevron.left.forwardslash.chevron.right", help: "Open in editor") { onAction(index, .editor) }
                actionButton("terminal", help: "Open Terminal") { onAction(index, .terminal) }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
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
        .frame(maxWidth: .infinity, alignment: .center)
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

// MARK: - Embedded SwiftTerm terminal (NSViewRepresentable)

/// Hosts a session's persistent `LocalProcessTerminalView`. SwiftTerm handles all
/// keyboard input, scrolling, and rendering; we only manage focus so keystrokes
/// reach the right pane in the menu-bar panel.
private struct EmbeddedTerminalView: NSViewRepresentable {
    let terminal: NotchTerminal
    let isFocused: Bool

    func makeNSView(context: Context) -> NSView {
        terminal.terminalView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard isFocused else { return }
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            if !window.isKeyWindow {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKey()
            }
            if window.firstResponder !== nsView {
                window.makeFirstResponder(nsView)
            }
        }
    }
}

// MARK: - Split terminal panes

private struct SplitTerminalPane: View {
    let descriptor: CodeTerminalPaneDescriptor
    @ObservedObject var terminal: NotchTerminal
    let isFocused: Bool
    let onFocus: () -> Void
    let onLaunch: () -> Void
    let onStop: () -> Void

    private var accentColor: Color { accent(for: descriptor.tool) }

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            if terminal.activeCLI == nil {
                idleBody
            } else {
                EmbeddedTerminalView(terminal: terminal, isFocused: isFocused)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(isFocused ? 0.48 : 0.36))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(accentColor.opacity(isFocused ? 0.48 : 0.14), lineWidth: 0.7)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onFocus)
    }

    private var titleBar: some View {
        HStack(spacing: 7) {
            CodeToolIcon(tool: descriptor.tool, size: 14)

            VStack(alignment: .leading, spacing: 0) {
                Text(descriptor.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                Text("$ \(descriptor.executableName)")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.28))
            }

            Spacer(minLength: 4)

            if terminal.activeCLI == nil {
                Button(action: onLaunch) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Run \(descriptor.displayName)")
            } else {
                Circle()
                    .fill(terminal.isRunning ? Color(red: 0.26, green: 0.79, blue: 0.40) : .white.opacity(0.25))
                    .frame(width: 5, height: 5)

                Button(action: onStop) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Close \(descriptor.displayName)")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.white.opacity(isFocused ? 0.055 : 0.025))
    }

    private var idleBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "terminal")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accentColor.opacity(0.70))
            Text("Ready")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
            Button(action: onLaunch) {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8, weight: .semibold))
                    Text("run")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(.black.opacity(0.78))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(accentColor.opacity(0.88))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Dashboard tile: full-width split CLI workspace

struct CodeDashboardTile: View {
    let projects: [CodeProjectDisplay]
    let onAction: (Int, CodeAction) -> Void
    let onRemove: (Int) -> Void
    let onDrop: ([URL]) -> Void
    let onLaunchCLI: (CodeCLITool) -> Void
    let terminals: [CodeCLITool: NotchTerminal]

    @State private var focusedTool: CodeCLITool = .claude

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            workspaceHeader

            HStack(spacing: 6) {
                ForEach(CodeTerminalPaneDescriptor.defaultPanes) { descriptor in
                    if let terminal = terminals[descriptor.tool] {
                        SplitTerminalPane(
                            descriptor: descriptor,
                            terminal: terminal,
                            isFocused: focusedTool == descriptor.tool,
                            onFocus: { focusedTool = descriptor.tool },
                            onLaunch: {
                                focusedTool = descriptor.tool
                                onLaunchCLI(descriptor.tool)
                            },
                            onStop: { terminal.stop() }
                        )
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, projects.first == nil ? 8 : 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let proj = projects.first {
                projectFooter(proj)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .dropDestination(for: URL.self) { urls, _ in
            onDrop(urls)
            return true
        }
    }

    private var workspaceHeader: some View {
        HStack(spacing: 7) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(NotchTheme.accent.opacity(0.86))
                .frame(width: 14)
            Text("CODE SPLIT")
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.42))
            Spacer(minLength: 8)
            Text(CodeTerminalPaneDescriptor.defaultPanes.map(\.executableName).joined(separator: " / "))
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.28))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.028))
    }

    private func projectFooter(_ proj: CodeProjectDisplay) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "folder")
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.22))
            Text("~/\(proj.name)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.white.opacity(0.28))
            if let branch = proj.status.branch {
                Text("·").foregroundStyle(.white.opacity(0.18))
                Text(branch)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.28))
                if proj.status.isDirty {
                    Circle().fill(Color(red: 1, green: 0.72, blue: 0.2)).frame(width: 4, height: 4)
                }
                if proj.status.ahead > 0 {
                    Text("↑\(proj.status.ahead)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.22))
                }
            }
            Spacer()
            Text("drop to pin")
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.15))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.03))
    }
}

// MARK: - Wide bar

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
