import AppKit

public enum ScreenLocator {
    package static func inferredNotchWidth(
        screenWidth: CGFloat,
        auxiliaryTopLeftAreaWidth: CGFloat?,
        safeAreaTop: CGFloat
    ) -> CGFloat? {
        guard safeAreaTop > 0, let auxiliaryTopLeftAreaWidth else {
            return nil
        }

        let width = (screenWidth - (2 * auxiliaryTopLeftAreaWidth)).rounded()
        guard width > 0, width < screenWidth else {
            return nil
        }

        return width
    }

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
            return ScreenInfo(
                frame: screen.frame,
                safeAreaTop: screen.safeAreaInsets.top,
                notchWidth: inferredNotchWidth(
                    screenWidth: screen.frame.width,
                    auxiliaryTopLeftAreaWidth: screen.auxiliaryTopLeftArea?.width,
                    safeAreaTop: screen.safeAreaInsets.top
                ),
                isMain: screen == NSScreen.main
            )
        }
    }
}
