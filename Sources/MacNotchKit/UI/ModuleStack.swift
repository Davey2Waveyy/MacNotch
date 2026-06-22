import SwiftUI

@MainActor
public final class ModuleRegistry {
    private var modules: [String: any NotchModule] = [:]
    private var registrationOrder: [String] = []

    public init() {}

    public func register(_ module: any NotchModule) {
        if modules[module.id] == nil { registrationOrder.append(module.id) }
        modules[module.id] = module
    }

    /// Returns modules in the requested id order, skipping unknown ids.
    public func ordered(by ids: [String]) -> [any NotchModule] {
        let enabledIDs = Set(ids)
        for module in modules.values {
            module.isEnabled = enabledIDs.contains(module.id)
        }

        var seen = Set<String>()
        return ids.compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            guard let module = modules[id] else { return nil }
            module.isEnabled = true
            return module
        }
    }

    public var all: [any NotchModule] { registrationOrder.compactMap { modules[$0] } }
}
