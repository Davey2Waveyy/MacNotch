import Foundation
import SwiftUI

@MainActor
final class SystemModule: NotchModule {
    let id = "system"
    let title = "Battery & System"
    var isEnabled = true

    final class StateBox: ObservableObject {
        @Published var sample = SystemSample(
            batteryPercent: nil,
            isCharging: false,
            cpuPercent: 0,
            ramUsedBytes: 0
        )
    }

    private let state = StateBox()
    private var timer: Timer?

    func collapsedView() -> AnyView? {
        nil
    }

    func expandedView() -> AnyView? {
        AnyView(SystemModuleBridge(box: state))
    }

    func dashboardTile() -> AnyView? {
        AnyView(SystemDashboardBridge(box: state))
    }

    func wideBarView() -> AnyView? {
        AnyView(SystemWideBarBridge(box: state))
    }

    func activate() {
        refreshTimer()
        Task { @MainActor in
            await refresh()
        }
    }

    func deactivate() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() async {
        state.sample = SystemSampler.sample()
    }

    private func refreshTimer() {
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }
}

private struct SystemModuleBridge: View {
    @ObservedObject var box: SystemModule.StateBox

    var body: some View {
        SystemExpandedView(sample: box.sample)
    }
}

private struct SystemDashboardBridge: View {
    @ObservedObject var box: SystemModule.StateBox

    var body: some View {
        SystemDashboardTile(sample: box.sample)
    }
}

private struct SystemWideBarBridge: View {
    @ObservedObject var box: SystemModule.StateBox

    var body: some View {
        SystemWideBar(sample: box.sample)
    }
}
