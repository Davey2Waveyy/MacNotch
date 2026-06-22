import CoreGraphics
import MacNotchKit

func screenLocatorTests() {
    func screen(top: CGFloat, notch: CGFloat?, main: Bool) -> ScreenInfo {
        ScreenInfo(
            frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            safeAreaTop: top,
            notchWidth: notch,
            isMain: main
        )
    }

    test("choose prefers screen with notch") {
        let external = screen(top: 0, notch: nil, main: true)
        let laptop = screen(top: 38, notch: 200, main: false)

        expectEqual(ScreenLocator.choose(from: [external, laptop]), laptop, "screen with notch wins")
    }

    test("choose falls back to main when no notch") {
        let external = screen(top: 0, notch: nil, main: true)
        let other = screen(top: 0, notch: nil, main: false)

        expectEqual(ScreenLocator.choose(from: [other, external]), external, "main screen wins without notch")
    }

    test("notch rect is top centered with given width") {
        let info = screen(top: 38, notch: 200, main: true)
        let rect = ScreenLocator.notchRect(for: info, defaultWidth: 220)

        expectEqual(rect.width, 200, "real notch width wins")
        expectEqual(rect.midX, info.frame.midX, "notch is centered")
        expectEqual(rect.maxY, info.frame.maxY, "notch hugs the top edge")
    }

    test("notch rect uses default width when no notch") {
        let info = screen(top: 0, notch: nil, main: true)
        let rect = ScreenLocator.notchRect(for: info, defaultWidth: 220)

        expectEqual(rect.width, 220, "default notch width used")
    }
}
