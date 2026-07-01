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
        @Published var tickers: [String] = []
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
        state.tickers = tickers
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
        state.tickers = tickers

        async let quoteResult = StocksFetcher.fetch(symbols: tickers)
        async let repoResult = fetchTrendingRepos()
        let skillsTask = Task.detached { CodingSkillDiscovery.discover() }

        state.quotes = await quoteResult
        state.trendingRepos = await repoResult
        state.installedSkills = await skillsTask.value

        state.isFetching = false
        state.isFetchingTrends = false
    }

    func addTicker(_ symbol: String) {
        let next = StockTickerSelection.add(symbol, to: tickers)
        guard next != tickers else { return }
        setTickers(next)
        Task { @MainActor in await refresh() }
    }

    func removeTicker(at index: Int) {
        let next = StockTickerSelection.remove(at: index, from: tickers)
        guard next != tickers else { return }
        setTickers(next)
        if state.quotes.indices.contains(index) {
            state.quotes.remove(at: index)
        }
    }

    private func setTickers(_ next: [String]) {
        tickers = next
        state.tickers = next
        UserDefaults.standard.set(next, forKey: Self.tickersKey)
    }

    private func fetchTrendingRepos() async -> [TrendingRepository] {
        let since = Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let url = GitHubTrendingRequest.url(since: since, limit: 5)
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue(NotchBrand.userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            return (try? GitHubTrendingParser.parse(data)) ?? []
        } catch {
            return []
        }
    }

    private func startTimer() {
        guard timer == nil else { return }
        let interval = EnergyRefreshPolicy.interval(base: 60, lowPowerMultiplier: 5)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.refresh() }
        }
        timer?.tolerance = EnergyRefreshPolicy.tolerance(for: interval)
    }
}

private struct StocksBridge: View {
    @ObservedObject var box: StocksModule.StateBox
    let onAdd: (String) -> Void
    let onRemove: (Int) -> Void

    var body: some View {
        StocksDashboardTile(
            quotes: box.quotes,
            tickers: box.tickers,
            trendingRepos: box.trendingRepos,
            installedSkills: box.installedSkills,
            isFetching: box.isFetching,
            isFetchingTrends: box.isFetchingTrends,
            onAdd: onAdd,
            onRemove: onRemove
        )
    }
}
