import CoreGraphics

public struct ScreenInfo: Equatable {
    public var frame: CGRect
    public var safeAreaTop: CGFloat
    public var notchWidth: CGFloat?
    public var isMain: Bool

    public init(frame: CGRect, safeAreaTop: CGFloat, notchWidth: CGFloat?, isMain: Bool) {
        self.frame = frame
        self.safeAreaTop = safeAreaTop
        self.notchWidth = notchWidth
        self.isMain = isMain
    }

    public var hasNotch: Bool {
        safeAreaTop > 0
    }
}
