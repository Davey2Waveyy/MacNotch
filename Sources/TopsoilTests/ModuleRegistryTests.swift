import SwiftUI
import TopsoilKit

@MainActor
final class FakeModule: NotchModule {
    let id: String
    var title: String
    var isEnabled = true
    init(_ id: String) { self.id = id; self.title = id }
    func collapsedView() -> AnyView? { nil }
    func expandedView() -> AnyView? { AnyView(EmptyView()) }
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

    test("ordered syncs module enablement with requested ids") {
        MainActor.assumeIsolated {
            let reg = ModuleRegistry()
            let a = FakeModule("a")
            let b = FakeModule("b")
            let c = FakeModule("c")
            reg.register(a)
            reg.register(b)
            reg.register(c)

            let ordered = reg.ordered(by: ["c", "missing", "a"])

            expectEqual(ordered.map(\.id), ["c", "a"], "requested known ids returned in order")
            expect(c.isEnabled, "requested module enabled")
            expect(a.isEnabled, "requested module enabled")
            expect(!b.isEnabled, "unrequested module disabled")
        }
    }
}
