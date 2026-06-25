import AppKit
import SwiftUI

/// NSView that moves the parent window on mouse-drag.
/// Placed in a fixed region of the UI so it acts as an explicit drag handle,
/// keeping chip drags and background drags completely separate.
final class WindowDragHandleNSView: NSView {
    private var startWindowOrigin: CGPoint = .zero
    private var startMouseScreen: CGPoint = .zero

    override var acceptsFirstResponder: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        startWindowOrigin = window?.frame.origin ?? .zero
        startMouseScreen = NSEvent.mouseLocation
    }

    override func mouseDragged(with event: NSEvent) {
        guard let w = window else { return }
        let cur = NSEvent.mouseLocation
        w.setFrameOrigin(CGPoint(
            x: startWindowOrigin.x + cur.x - startMouseScreen.x,
            y: startWindowOrigin.y + cur.y - startMouseScreen.y
        ))
    }

    override func cursorUpdate(with event: NSEvent) { NSCursor.openHand.set() }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .openHand) }
}

struct WindowDragHandleView: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragHandleNSView { WindowDragHandleNSView() }
    func updateNSView(_ v: WindowDragHandleNSView, context: Context) {}
}
