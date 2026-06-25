import SwiftUI

@MainActor
final class StocksModule: NotchModule {
    let id = "stocks"
    let title = "Stocks"
    var isEnabled = true
    var isFullPageTile: Bool { true }

    private static let defaultTickers = ["AAPL", "NVDA", "MSFT"]
    private static let tickersKey = "io.local.macnotch.stockTickers"

    final class StateBox: ObservableObject {
        @Published var quotes: [StockQuote] = []
        @Published var trendingRepos: [TrendingRepository] = []
        @Published var installedSkills: [InstalledCodingSkill] = []
        @Published var isFetching = false
        @Published var isFetchingTrends = false
    }

    private let state = StateBox()
    private var tickers: [String]
    private var timer: Timer?

    init() {
        tickers = UserDefaults.standard.stringArray(forKey: Self.tickersKey) ?? Self.defaultTickers
    }

    func collapsedView() -> AnyView? { nil }
    func expandedView() -> AnyView? { nil }

    func dashboardTile() -> AnyView? {
        AnyView(StocksBridge(
            box: state,
            onAdd: { [weak self] sym in self?.addTicker(sym) },
            onRemove: { [weak self] idx in self?.removeTicker(at: idx) }
        ))
    }

    func wideBarView() -> AnyView? { nil }

    func activate() {
        startTimer()
        Task { @MainActor in await refresh() }
    }

    func deactivate() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() async {
        state.isFetching = true
        state.isFetchingTrends = true

        async let quoteResult = StocksFetcher.fetch(symbols: tickers)
        async let repoResult = GitHubTrendingFetcher.fetch(limit: 5)
        let skillsTask = Task.detached { CodingSkillDiscovery.discover() }

        state.quotes = await quoteResult
        state.trendingRepos = await repoResult
        state.installedSkills = await skillsTask.value

        state.isFetching = false
        state.isFetchingTrends = false
    }

    func addTicker(_ symbol: String) {
        let clean = symbol.uppercased().trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, !tickers.contains(clean) else { return }
        tickers.append(clean)
        UserDefaults.standard.set(tickers, forKey: Self.tickersKey)
        Task { @MainActor in await refresh() }
    }

    func removeTicker(at index: Int) {
        guard tickers.indices.contains(index) else { return }
        tickers.remove(at: index)
        UserDefaults.standard.set(tickers, forKey: Self.tickersKey)
        if state.quotes.indices.contains(index) {
            state.quotes.remove(at: index)
        }
    }

    private func startTimer() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
    }
}

private struct StocksBridge: View {
    @ObservedObject var box: StocksModule.StateBox
    let onAdd: (String) -> Void
    let onRemove: (Int) -> Void

    var body: some View {
        StocksDashboardTile(
            quotes: box.quotes,
            trendingRepos: box.trendingRepos,
            installedSkills: box.installedSkills,
            isFetching: box.isFetching,
            isFetchingTrends: box.isFetchingTrends,
            onAdd: onAdd,
            onRemove: onRemove
        )
    }
}
