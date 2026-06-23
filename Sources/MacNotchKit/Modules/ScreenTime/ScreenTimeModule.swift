import AppKit
import SwiftUI

@MainActor
final class ScreenTimeModule: NotchModule {
    let id = "screenTime"
    let title = "Screen Time"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var ranked: [AppUsage] = []
        @Published var total: TimeInterval = 0
        @Published var switches: Int = 0
    }

    private let state = StateBox()
    private var tracker = ScreenTimeTracker()
    private var observer: NSObjectProtocol?
    private var tick: Timer?
    private let storeURL: URL

    init() {
        storeURL = Self.defaultURL()
        loadSwitchCount()
    }

    func collapsedView() -> AnyView? { nil }
    func expandedView() -> AnyView? { nil }

    func dashboardTile() -> AnyView? {
        AnyView(ScreenTimeBridge(box: state))
    }

    func activate() {
        // Seed with the current frontmost app.
        if let app = NSWorkspace.shared.frontmostApplication {
            tracker.focus(bundleID: app.bundleIdentifier ?? "unknown",
                          name: app.localizedName ?? "Unknown",
                          at: Date())
        }
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            MainActor.assumeIsolated {
                self.handleActivation(app)
            }
        }
        tick = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.publish() }
        }
        publish()
    }

    func deactivate() {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
        tick?.invalidate()
        tick = nil
        tracker.settle(now: Date())
    }

    func refresh() async { publish() }

    private func handleActivation(_ app: NSRunningApplication?) {
        guard let app else { return }
        tracker.focus(bundleID: app.bundleIdentifier ?? "unknown",
                      name: app.localizedName ?? "Unknown",
                      at: Date())
        state.switches += 1
        saveSwitchCount()
        publish()
    }

    private func publish() {
        tracker.settle(now: Date())
        state.ranked = tracker.ranked
        state.total = tracker.totalSeconds
    }

    // MARK: - Persistence (switch count only; usage is session-scoped)

    private struct Persisted: Codable { var day: Date; var switches: Int }

    private func loadSwitchCount() {
        guard let data = try? Data(contentsOf: storeURL),
              let p = try? JSONDecoder().decode(Persisted.self, from: data),
              Calendar.current.isDateInToday(p.day) else { return }
        state.switches = p.switches
    }

    private func saveSwitchCount() {
        let p = Persisted(day: Calendar.current.startOfDay(for: Date()), switches: state.switches)
        if let data = try? JSONEncoder().encode(p) {
            try? data.write(to: storeURL, options: .atomic)
        }
    }

    static func defaultURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = support.appendingPathComponent("MacNotch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("screentime.json")
    }
}

private struct ScreenTimeBridge: View {
    @ObservedObject var box: ScreenTimeModule.StateBox
    var body: some View {
        ScreenTimeDashboardTile(ranked: box.ranked, total: box.total, switches: box.switches)
    }
}
