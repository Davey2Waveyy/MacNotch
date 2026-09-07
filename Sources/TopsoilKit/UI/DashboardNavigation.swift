import Foundation
import CoreGraphics

/// Value-only page planning, shared by navigation and rendering.
public struct DashboardModuleDescriptor: Equatable, Sendable {
    public let id: String
    public let title: String
    public let isFullPage: Bool

    public init(id: String, title: String, isFullPage: Bool = false) {
        self.id = id
        self.title = title
        self.isFullPage = isFullPage
    }
}

public enum DashboardNavigation {
    public static func pages(
        modules: [DashboardModuleDescriptor],
        query: String = "",
        layout: DashboardLayoutPreference = .pagedTiles
    ) -> [[DashboardModuleDescriptor]] {
        let terms = query.split(whereSeparator: \.isWhitespace).map(String.init)
        let filtered = modules.filter { module in
            terms.allSatisfy { term in
                "\(module.title) \(module.id) \(ModulePresentation.description(for: module.id))"
                    .localizedStandardContains(term)
            }
        }
        let capacity = layout == .fullPageFocus ? 1 : (layout == .priority ? 4 : 5)
        var pages: [[DashboardModuleDescriptor]] = []
        var current: [DashboardModuleDescriptor] = []
        for module in filtered {
            if module.isFullPage {
                if !current.isEmpty { pages.append(current); current = [] }
                pages.append([module])
            } else {
                current.append(module)
                if current.count == capacity { pages.append(current); current = [] }
            }
        }
        if !current.isEmpty { pages.append(current) }
        return pages
    }

    public static func clampedPage(_ page: Int, count: Int) -> Int {
        min(max(0, page), max(0, count - 1))
    }

    public static let fullDashboardHeight: CGFloat = 350
    public static let compactDashboardHeight: CGFloat = 280

    // ponytail: coarse short/tall split, not per-pixel content measurement. Rich
    // and full-page tiles fill the taller panel; pages made only of these short
    // "tool" surfaces shrink. Tune the set or the two heights if snapshots read
    // cramped or empty.
    private static let shortTileModuleIDs: Set<String> = ["customize", "commandPalette"]

    /// Panel height for a single page: shrinks only when every tile is a short
    /// tool surface, so rich tiles never get squeezed.
    public static func height(for page: [DashboardModuleDescriptor]) -> CGFloat {
        guard !page.isEmpty else { return fullDashboardHeight }
        let allShort = page.allSatisfy { !$0.isFullPage && shortTileModuleIDs.contains($0.id) }
        return allShort ? compactDashboardHeight : fullDashboardHeight
    }

    /// Panel height for the currently-visible page.
    public static func height(
        modules: [DashboardModuleDescriptor],
        page: Int,
        layout: DashboardLayoutPreference = .pagedTiles
    ) -> CGFloat {
        let pages = pages(modules: modules, layout: layout)
        guard !pages.isEmpty else { return fullDashboardHeight }
        return height(for: pages[clampedPage(page, count: pages.count)])
    }

    public static func title(for page: [DashboardModuleDescriptor], index: Int) -> String {
        if page.count == 1 { return page[0].title }
        return index == 0 ? "Essentials" : "More tools"
    }
}

public enum ModulePresentation {
    public static func icon(for id: String) -> String {
        switch id {
        case "media": "music.note"
        case "quickToggles": "switch.2"
        case "timers": "timer"
        case "actions": "bolt"
        case "shelf": "tray.and.arrow.down"
        case "code": "terminal"
        case "commandPalette": "command"
        case "stocks": "chart.line.uptrend.xyaxis"
        case "garden": "leaf"
        case "screenTime": "hourglass"
        case "pomodoro": "scope"
        case "reminders": "checklist"
        case "calendar": "calendar"
        case "clipboard": "doc.on.clipboard"
        case "system": "gauge.with.dots.needle.50percent"
        case "launcher": "square.grid.2x2"
        case "customize": "slider.horizontal.3"
        default: "square.grid.2x2"
        }
    }

    public static func description(for id: String) -> String {
        switch id {
        case "media": "Music, playback controls, and lyrics."
        case "quickToggles": "Quick access to display, audio, and awake controls."
        case "timers": "Quick countdowns and custom timers."
        case "actions": "Open apps and everyday Mac shortcuts."
        case "shelf": "Keep files close. Drop them in and drag them out."
        case "code": "Projects, Git status, and terminal tools."
        case "commandPalette": "Find actions and switch workspaces."
        case "stocks": "Your watchlist and market prices."
        case "garden": "A small living space in your notch."
        case "screenTime": "See where your time goes on this Mac."
        case "pomodoro": "Alternate focused work with short breaks."
        case "reminders": "Keep upcoming tasks within reach."
        case "calendar": "Your schedule and upcoming events."
        case "clipboard": "Find and reuse recently copied text."
        case "system": "Battery, CPU, and memory at a glance."
        case "launcher": "Your favorite apps, one click away."
        case "customize": "Adjust your workspace without leaving the notch."
        default: "Available in your Topsoil workspace."
        }
    }
}
