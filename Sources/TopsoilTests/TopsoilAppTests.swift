import TopsoilKit

func macNotchAppTests() {
    test("TopsoilApp exposes a main-actor run entry point") {
        let run: @MainActor () -> Void = TopsoilApp.run
        _ = run
        expect(true, "TopsoilApp.run is available")
    }
}
