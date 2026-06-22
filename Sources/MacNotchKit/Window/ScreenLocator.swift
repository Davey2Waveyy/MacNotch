import AppKit

public enum ScreenLocator {
    public static func choose(from screens: [ScreenInfo]) -> ScreenInfo? {
        if let notched = screens.first(where: { $0.hasNotch }) {
            return notched
        }

        if let main = screens.first(where: { $0.isMain }) {
            return main
        }

        return screens.first
    }

    public static func notchRect(for screen: ScreenInfo, defaultWidth: CGFloat) -> CGRect {
        let width = screen.notchWidth ?? defaultWidth
        let height = max(screen.safeAreaTop, 32)
        let x = screen.frame.midX - (width / 2)
        let y = screen.frame.maxY - height

        return CGRect(x: x, y: y, width: width, height: height)
    }

    public static func current() -> [ScreenInfo] {
        NSScreen.screens.map { screen in
            let auxiliaryTopLeftArea = screen.auxiliaryTopLeftArea
            let notchWidth: CGFloat? = screen.safeAreaInsets.top > 0
                ? (screen.frame.width - (2 * (auxiliaryTopLeftArea?.width ?? 0))).rounded()
                : nil

            return ScreenInfo(
                frame: screen.frame,
                safeAreaTop: screen.safeAreaInsets.top,
                notchWidth: notchWidth.map { $0 > 0 ? $0 : nil } ?? nil,
                isMain: screen == NSScreen.main
            )
        }
    }
}
