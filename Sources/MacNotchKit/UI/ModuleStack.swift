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
        ids.compactMap { modules[$0] }
    }

    public var all: [any NotchModule] { registrationOrder.compactMap { modules[$0] } }
}
