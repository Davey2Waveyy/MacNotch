import Foundation

struct StockQuote: Equatable, Sendable {
    var symbol: String
    var price: Double
    var previousClose: Double
    var history: [Double]

    var changePercent: Double {
        guard previousClose > 0 else { return 0 }
        return (price - previousClose) / previousClose * 100
    }

    var isUp: Bool { changePercent >= 0 }
}

enum StocksFetcher {
    static func fetch(symbols: [String]) async -> [StockQuote] {
        await withTaskGroup(of: (Int, StockQuote?).self) { group in
            for (i, symbol) in symbols.enumerated() {
                group.addTask { (i, try? await fetchOne(symbol: symbol)) }
            }
            var pairs: [(Int, StockQuote)] = []
            for await (i, quote) in group {
                if let q = quote { pairs.append((i, q)) }
            }
            return pairs.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private static func fetchOne(symbol: String) async throws -> StockQuote {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&range=1mo") else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )
        let (data, _) = try await URLSession.shared.data(for: req)
        return try parse(data: data, symbol: symbol)
    }

    private static func parse(data: Data, symbol: String) throws -> StockQuote {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let chart = json["chart"] as? [String: Any],
            let results = chart["result"] as? [[String: Any]],
            let first = results.first
        else { throw URLError(.cannotParseResponse) }

        let meta = first["meta"] as? [String: Any] ?? [:]
        let price = meta["regularMarketPrice"] as? Double ?? 0
        let prevClose = meta["chartPreviousClose"] as? Double
            ?? meta["previousClose"] as? Double
            ?? 0

        let closes = ((first["indicators"] as? [String: Any])?["quote"] as? [[String: Any]])?
            .first?["close"] as? [Double?] ?? []

        return StockQuote(
            symbol: symbol,
            price: price,
            previousClose: prevClose,
            history: closes.compactMap { $0 }
        )
    }
}
