import SwiftUI
import Combine

@MainActor
public final class GardenModule: NotchModule {
    public let id = "garden"
    public let title = "Notch Garden"
    public var isEnabled = true
    
    public init() {}
    
    public func collapsedView() -> AnyView? {
        // Render the actual live growing pixel canvas in the collapsed tray next to the notch!
        // This allows developers to monitor their plant's growth visually while working.
        AnyView(
            GardenCanvasView()
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        )
    }
    
    public func expandedView() -> AnyView? {
        AnyView(
            GardenExpandedView()
        )
    }
    
    public func activate() {}
    public func deactivate() {}
    public func refresh() async {}
}
