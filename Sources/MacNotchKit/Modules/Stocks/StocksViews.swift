import AppKit
import SwiftUI

struct StocksDashboardTile: View {
    let quotes: [StockQuote]
    let trendingRepos: [TrendingRepository]
    let installedSkills: [InstalledCodingSkill]
    let isFetching: Bool
    let isFetchingTrends: Bool
    let onAdd: (String) -> Void
    let onRemove: (Int) -> Void

    @State private var isEditing = false
    @State private var newTicker = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            HStack(alignment: .top, spacing: 12) {
                marketColumn
                    .frame(width: 342)
                repoColumn
                    .frame(maxWidth: .infinity)
                skillsColumn
                    .frame(width: 330)
            }
            .padding(.top, 10)
            if isEditing {
                addRow
                    .padding(.top, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(NotchTheme.accent)
            Text("MARKETS + CODE")
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.55))
            Spacer(minLength: 0)
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                    isEditing.toggle()
                    if isEditing { inputFocused = true }
                }
            } label: {
                Image(systemName: isEditing ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isEditing ? NotchTheme.accent : .white.opacity(0.35))
            }
            .buttonStyle(.plain)
            .help(isEditing ? "Done" : "Add ticker")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Content

    @ViewBuilder
    private var marketColumn: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionLabel("Stocks", systemImage: "chart.line.uptrend.xyaxis")
            if isFetching && quotes.isEmpty {
                emptyLine("Fetching quotes")
            } else if quotes.isEmpty {
                emptyLine("Tap + to add a ticker")
            } else {
                VStack(spacing: 5) {
                    ForEach(quotes.indices, id: \.self) { i in
                        HStack(spacing: 0) {
                            StockRow(quote: quotes[i])
                            if isEditing {
                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.80)) {
                                        onRemove(i)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(red: 0.92, green: 0.37, blue: 0.37))
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 8)
                                .transition(.scale(scale: 0.6).combined(with: .opacity))
                            }
                        }
                        .animation(.spring(response: 0.25, dampingFraction: 0.80), value: isEditing)
                    }
                }
            }
        }
    }

    private var repoColumn: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionLabel("Repos today", systemImage: "star")
            if isFetchingTrends && trendingRepos.isEmpty {
                emptyLine("Fetching GitHub trends")
            } else if trendingRepos.isEmpty {
                emptyLine("No repo trends yet")
            } else {
                VStack(spacing: 5) {
                    ForEach(Array(trendingRepos.prefix(4))) { repo in
                        RepoTrendRow(repo: repo)
                    }
                }
            }
        }
    }

    private var skillsColumn: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionLabel("Installed skills", systemImage: "terminal")
            VStack(spacing: 6) {
                ForEach(CodeCLITool.allCases) { tool in
                    SkillGroupRow(
                        tool: tool,
                        skills: installedSkills.filter { $0.cli == tool }
                    )
                }
            }
        }
    }

    private func sectionLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(NotchTheme.accent.opacity(0.85))
            Text(title.uppercased())
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            Spacer(minLength: 0)
        }
    }

    private func emptyLine(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white.opacity(0.28))
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .center)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.035)))
    }

    // MARK: - Add ticker row

    private var addRow: some View {
        HStack(spacing: 8) {
            Text("$")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(NotchTheme.accent.opacity(0.70))
            TextField("AAPL, TSLA…", text: $newTicker)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .onSubmit { submitTicker() }
            Button { submitTicker() } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(newTicker.isEmpty ? .white.opacity(0.15) : NotchTheme.accent)
            }
            .buttonStyle(.plain)
            .disabled(newTicker.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(NotchTheme.accent.opacity(0.25), lineWidth: 0.5)
                )
        )
    }

    private func submitTicker() {
        let clean = newTicker.uppercased().trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return }
        onAdd(clean)
        newTicker = ""
    }
}

// MARK: - Coding intel rows

private struct RepoTrendRow: View {
    let repo: TrendingRepository

    var body: some View {
        Button {
            NSWorkspace.shared.open(repo.url)
        } label: {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(repo.fullName)
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(1)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white.opacity(0.22))
                    }
                    Text(repo.description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                         ? repo.description ?? ""
                         : "No description")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.35))
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(starLabel(repo.stars))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(NotchTheme.accent.opacity(0.82))
                    if let language = repo.language, !language.isEmpty {
                        Text(language)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.white.opacity(0.28))
                            .lineLimit(1)
                    }
                }
                .frame(width: 54, alignment: .trailing)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.045)))
        }
        .buttonStyle(.plain)
        .help("Open \(repo.fullName) on GitHub")
    }

    private func starLabel(_ count: Int) -> String {
        guard count >= 1_000 else { return "\(count)" }
        return String(format: "%.1fk", Double(count) / 1_000)
    }
}

private struct SkillGroupRow: View {
    let tool: CodeCLITool
    let skills: [InstalledCodingSkill]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: tool.systemImage)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(codeAccent(for: tool))
                .frame(width: 16, height: 18)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(tool.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                    Text("\(skills.count)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.32))
                }
                if skills.isEmpty {
                    Text("No skills found")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.24))
                } else {
                    Text(skills.prefix(4).map(\.name).joined(separator: "  "))
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.38))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.04)))
    }
}

private func codeAccent(for tool: CodeCLITool) -> Color {
    switch tool {
    case .claude: return Color(red: 0.78, green: 0.52, blue: 1.00)
    case .codex: return Color(red: 0.36, green: 0.78, blue: 1.00)
    case .cursor: return Color(red: 0.27, green: 0.98, blue: 0.72)
    }
}

// MARK: - Stock row

struct StockRow: View {
    let quote: StockQuote

    private var trendColor: Color {
        quote.isUp
            ? Color(red: 0.33, green: 0.82, blue: 0.52)
            : Color(red: 0.92, green: 0.37, blue: 0.37)
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(quote.symbol)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 48, alignment: .leading)

            SparklineView(values: quote.history, color: trendColor)
                .frame(height: 22)
                .frame(maxWidth: .infinity)

            VStack(alignment: .trailing, spacing: 1) {
                Text(String(format: "$%.2f", quote.price))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                let pct = quote.changePercent
                Text(String(format: "%@%.2f%%", pct >= 0 ? "+" : "", pct))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(trendColor)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sparkline

struct SparklineView: View {
    let values: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            if values.count >= 2,
               let minV = values.min(),
               let maxV = values.max() {
                let range = maxV == minV ? 1.0 : maxV - minV
                let pts: [CGPoint] = values.enumerated().map { i, v in
                    CGPoint(
                        x: CGFloat(i) / CGFloat(values.count - 1) * w,
                        y: h - (CGFloat((v - minV) / range) * (h - 4) + 2)
                    )
                }
                Path { p in
                    p.move(to: pts[0])
                    pts.dropFirst().forEach { p.addLine(to: $0) }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
    }
}
