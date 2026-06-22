import Foundation
import IOKit.ps
import Darwin

public enum SystemSampler {
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
        let max = description[kIOPSMaxCapacityKey] as? Int ?? 100
        let state = description[kIOPSPowerSourceStateKey] as? String
        let percent = current.map { Int((Double($0) / Double(max) * 100).rounded()) }
        return (percent, state == kIOPSACPowerValue)
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

        let user = Double(load.cpu_ticks.0)
        let system = Double(load.cpu_ticks.1)
        let idle = Double(load.cpu_ticks.2)
        let nice = Double(load.cpu_ticks.3)
        let busy = user + system + nice
        let total = busy + idle
        return total > 0 ? busy / total * 100 : 0
    }
}
