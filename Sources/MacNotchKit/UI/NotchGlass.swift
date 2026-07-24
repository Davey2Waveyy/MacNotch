import AppKit
import SwiftUI

/// Panel silhouette for a notch dropdown. Both the bottom corners and (when
/// expanded) the top corners are rounded, giving the panel a full card shape.
struct NotchPanelShape: Shape {
    var bottomRadius: CGFloat
    var topRadius: CGFloat = 0

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(bottomRadius, topRadius) }
        set { bottomRadius = newValue.first; topRadius = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let br = max(0, min(bottomRadius, min(rect.width, rect.height) / 2))
        let tr = max(0, min(topRadius,    min(rect.width, rect.height) / 2))
        var p = Path()
        if tr > 0 {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY + tr))
            p.addArc(center: CGPoint(x: rect.minX + tr, y: rect.minY + tr),
                     radius: tr, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
            p.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                     radius: tr, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        } else {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        p.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                 radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + br, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + br, y: rect.maxY - br),
                 radius: br, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Clipped visual effect view

/// `NSVisualEffectView` subclass that applies a `CAShapeLayer` mask in `layout()`
/// so the blur is truly clipped to a rounded rectangle. SwiftUI `.clipShape()` and
/// even `.layer.cornerRadius + masksToBounds` don't fully clip the compositor-level
/// blur — a proper layer mask is required.
final class MaskedVisualEffectView: NSVisualEffectView {
    var shapeCornerRadius: CGFloat = 0 {
        didSet { if oldValue != shapeCornerRadius { applyMask() } }
    }

    override func layout() {
        super.layout()
        applyMask()
    }

    private func applyMask() {
        wantsLayer = true
        guard bounds.size != .zero else { return }
        let mask = (layer?.mask as? CAShapeLayer) ?? {
            let m = CAShapeLayer()
            layer?.mask = m
            return m
        }()
        let path = CGMutablePath()
        let r = shapeCornerRadius
        path.addRoundedRect(in: bounds, cornerWidth: r, cornerHeight: r)
        // Disable implicit animation so the mask doesn't lag behind during resize.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        mask.path = path
        CATransaction.commit()
    }
}

// MARK: - Snapshot mode

/// True when rendering offscreen via `ImageRenderer` (which can't render
/// AppKit-backed views — they'd draw as yellow placeholder blocks). Platform
/// views check this and swap in a SwiftUI approximation or render nothing.
private struct NotchSnapshotModeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var notchSnapshotMode: Bool {
        get { self[NotchSnapshotModeKey.self] }
        set { self[NotchSnapshotModeKey.self] = newValue }
    }
}

/// `.dropDestination` that detaches in snapshot mode — ImageRenderer draws
/// platform drop targets as full-frame yellow placeholder blocks.
private struct URLDropTarget: ViewModifier {
    @Environment(\.notchSnapshotMode) private var snapshotMode
    let onDrop: ([URL]) -> Void

    func body(content: Content) -> some View {
        if snapshotMode {
            content
        } else {
            content.dropDestination(for: URL.self) { urls, _ in
                onDrop(urls)
                return true
            }
        }
    }
}

/// `.onDrag` source that detaches in snapshot mode for the same reason.
private struct URLDragSource: ViewModifier {
    @Environment(\.notchSnapshotMode) private var snapshotMode
    let url: URL

    func body(content: Content) -> some View {
        if snapshotMode {
            content
        } else {
            content.onDrag { NSItemProvider(object: url as NSURL) }
        }
    }
}

extension View {
    func urlDropTarget(_ onDrop: @escaping ([URL]) -> Void) -> some View {
        modifier(URLDropTarget(onDrop: onDrop))
    }

    func urlDragSource(_ url: URL) -> some View {
        modifier(URLDragSource(url: url))
    }
}

// MARK: - SwiftUI wrapper

/// Real macOS glass: an `NSVisualEffectView` that blurs whatever sits behind the
/// panel. Tinted dark on top so it stays legible over bright desktops.
/// In snapshot mode the blur is approximated with a flat dark fill.
struct VisualEffectBackground: View {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var cornerRadius: CGFloat = 0
    @Environment(\.notchSnapshotMode) private var snapshotMode

    var body: some View {
        if snapshotMode {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.13).opacity(0.90))
        } else {
            VisualEffectRepresentable(
                material: material,
                blendingMode: blendingMode,
                cornerRadius: cornerRadius
            )
        }
    }
}

private struct VisualEffectRepresentable: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var cornerRadius: CGFloat

    func makeNSView(context: Context) -> MaskedVisualEffectView {
        let view = MaskedVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ view: MaskedVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.shapeCornerRadius = cornerRadius
    }
}
