import Foundation
import IOKit.ps
import Darwin

package struct CPULoadSnapshot: Sendable, Equatable {
    package let user: UInt64
    package let system: UInt64
    package let idle: UInt64
    package let nice: UInt64

    package init(user: UInt64, system: UInt64, idle: UInt64, nice: UInt64) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    fileprivate init(_ load: host_cpu_load_info) {
        self.init(
            user: UInt64(load.cpu_ticks.0),
            system: UInt64(load.cpu_ticks.1),
            idle: UInt64(load.cpu_ticks.2),
            nice: UInt64(load.cpu_ticks.3)
        )
    }
}

private final class CPUSnapshotStore: @unchecked Sendable {
    private let lock = NSLock()
    private var previous: CPULoadSnapshot?

    func percent(for current: CPULoadSnapshot) -> Double {
        lock.lock()
        defer { lock.unlock() }

        let percent = SystemSampler.cpuUsagePercent(previous: previous, current: current)
        previous = current
        return percent
    }
}

public enum SystemSampler {
    private static let cpuSnapshotStore = CPUSnapshotStore()

    public static func sample() -> SystemSample {
        let (batteryPercent, isCharging) = batteryStatus()
        return SystemSample(
            batteryPercent: batteryPercent,
            isCharging: isCharging,
            cpuPercent: cpuUsage(),
            ramUsedBytes: ramUsedBytes()
        )
    }

    private static func batteryStatus() -> (Int?, Bool) {
        guard
            let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
            let source = list.first,
            let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any]
        else {
            return (nil, false)
        }

        let current = description[kIOPSCurrentCapacityKey] as? Int
        let max = description[kIOPSMaxCapacityKey] as? Int
        let state = description[kIOPSPowerSourceStateKey] as? String
        let percent = batteryPercent(current: current, max: max)
        return (percent, state == kIOPSACPowerValue)
    }

    package static func batteryPercent(current: Int?, max: Int?) -> Int? {
        guard let current, let max, max > 0 else { return nil }

        let percent = (Double(current) / Double(max)) * 100
        guard percent.isFinite else { return nil }
        return Int(percent.rounded())
    }

    private static func ramUsedBytes() -> UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { integerPointer in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, integerPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }

        var pageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else { return 0 }
        let usedPages = UInt64(stats.active_count) + UInt64(stats.wire_count)
        return usedPages * UInt64(pageSize)
    }

    private static func cpuUsage() -> Double {
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &load) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { integerPointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, integerPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0 }
        return cpuSnapshotStore.percent(for: CPULoadSnapshot(load))
    }

    package static func cpuUsagePercent(previous: CPULoadSnapshot?, current: CPULoadSnapshot) -> Double {
        guard let previous else { return 0 }
        guard
            current.user >= previous.user,
            current.system >= previous.system,
            current.idle >= previous.idle,
            current.nice >= previous.nice
        else {
            return 0
        }

        let userDelta = current.user - previous.user
        let systemDelta = current.system - previous.system
        let idleDelta = current.idle - previous.idle
        let niceDelta = current.nice - previous.nice

        let busyDelta = Double(userDelta + systemDelta + niceDelta)
        let totalDelta = busyDelta + Double(idleDelta)
        guard totalDelta > 0, busyDelta.isFinite, totalDelta.isFinite else { return 0 }
        return (busyDelta / totalDelta) * 100
    }
}
