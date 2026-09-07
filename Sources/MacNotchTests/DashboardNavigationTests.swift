import MacNotchKit

func dashboardNavigationTests() {
    let tools = [
        DashboardModuleDescriptor(id: "media", title: "Now Playing"),
        DashboardModuleDescriptor(id: "timers", title: "Timers"),
        DashboardModuleDescriptor(id: "code", title: "Code", isFullPage: true),
        DashboardModuleDescriptor(id: "shelf", title: "Drop Shelf")
    ]
    test("dashboard keeps full-width tools isolated and preserves module order") {
        expectEqual(DashboardNavigation.pages(modules: tools).map { $0.map(\.id) },
                    [["media", "timers"], ["code"], ["shelf"]], "mixed pages")
    }
    test("dashboard search finds descriptions and requires all terms") {
        expectEqual(DashboardNavigation.pages(modules: tools, query: " MUSIC ").flatMap { $0.map(\.id) }, ["media"], "description search")
        expectEqual(DashboardNavigation.pages(modules: tools, query: "music timer").count, 0, "all terms")
        expectEqual(DashboardNavigation.pages(modules: tools, query: "  \n "), DashboardNavigation.pages(modules: tools), "whitespace")
    }
    test("focus layout gives every tool its own page") {
        expectEqual(DashboardNavigation.pages(modules: tools, layout: .fullPageFocus).map { $0.count }, [1, 1, 1, 1], "focus pages")
    }
    test("priority layout reserves space for the lead tile") {
        let modules = (0..<6).map { DashboardModuleDescriptor(id: "\($0)", title: "Tool \($0)") }
        expectEqual(DashboardNavigation.pages(modules: modules).map { $0.count }, [5, 1], "standard capacity")
        expectEqual(DashboardNavigation.pages(modules: modules, layout: .priority).map { $0.count }, [4, 2], "priority capacity")
    }
    test("dashboard safely clamps stale and negative page selections") {
        expectEqual(DashboardNavigation.clampedPage(-1, count: 4), 0, "negative")
        expectEqual(DashboardNavigation.clampedPage(9, count: 2), 1, "shrunk list")
        expectEqual(DashboardNavigation.clampedPage(2, count: 0), 0, "empty list")
        expectEqual(DashboardNavigation.pages(modules: []).count, 0, "no modules")
    }
}
