import MacNotchKit

func macNotchAppTests() {
    test("MacNotchApp exposes a main-actor run entry point") {
        let run: @MainActor () -> Void = MacNotchApp.run
        _ = run
        expect(true, "MacNotchApp.run is available")
    }
}
