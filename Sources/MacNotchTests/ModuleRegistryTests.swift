import SwiftUI
import MacNotchKit

@MainActor
final class FakeModule: NotchModule {
    let id: String
    var title: String
    var isEnabled = true
    init(_ id: String) { self.id = id; self.title = id }
    func collapsedView() -> AnyView? { nil }
    func expandedView() -> AnyView { AnyView(EmptyView()) }
    func activate() {}
    func deactivate() {}
    func refresh() async {}
}

func moduleRegistryTests() {
    test("ordered follows requested ids") {
        MainActor.assumeIsolated {
            let reg = ModuleRegistry()
            reg.register(FakeModule("a"))
            reg.register(FakeModule("b"))
            reg.register(FakeModule("c"))
            expectEqual(reg.ordered(by: ["c", "a"]).map(\.id), ["c", "a"], "order")
        }
    }
    test("unknown ids are ignored") {
        MainActor.assumeIsolated {
            let reg = ModuleRegistry()
            reg.register(FakeModule("a"))
            expectEqual(reg.ordered(by: ["zzz", "a"]).map(\.id), ["a"], "skip unknown")
        }
    }
}
