import TopsoilKit

func stocksSelectionTests() {
    test("stocks: ticker input is normalized for finance symbols") {
        expectEqual(StockTickerSelection.normalized(" aapl "), "AAPL", "uppercase and trim")
        expectEqual(StockTickerSelection.normalized("brk.b"), "BRK.B", "class suffix dot is kept")
        expectEqual(StockTickerSelection.normalized("btc-usd"), "BTC-USD", "dash is kept")
        expect(StockTickerSelection.normalized(" ") == nil, "blank input is ignored")
    }

    test("stocks: ticker selection adds unique symbols and removes by index") {
        var tickers = ["AAPL", "NVDA"]
        tickers = StockTickerSelection.add(" msft ", to: tickers)
        tickers = StockTickerSelection.add("aapl", to: tickers)
        expectEqual(tickers, ["AAPL", "NVDA", "MSFT"], "adds normalized symbols without duplicates")

        expectEqual(StockTickerSelection.remove(at: 1, from: tickers), ["AAPL", "MSFT"], "removes selected ticker")
        expectEqual(StockTickerSelection.remove(at: 9, from: tickers), tickers, "out-of-range remove is safe")
    }
}
