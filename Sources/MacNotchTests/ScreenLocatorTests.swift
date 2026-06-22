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

    test("choose falls back to first screen when no notch and no main") {
        let first = screen(top: 0, notch: nil, main: false)
        let second = screen(top: 0, notch: nil, main: false)

        expectEqual(ScreenLocator.choose(from: [first, second]), first, "first screen wins without notch or main")
    }

    test("inferred notch width requires an auxiliary area and a plausible width") {
        expectEqual(
            ScreenLocator.inferredNotchWidth(screenWidth: 1512, auxiliaryTopLeftAreaWidth: nil, safeAreaTop: 38),
            nil,
            "missing auxiliary area falls back to nil"
        )
        expectEqual(
            ScreenLocator.inferredNotchWidth(screenWidth: 1512, auxiliaryTopLeftAreaWidth: 656, safeAreaTop: 38),
            200,
            "plausible inferred width is kept"
        )
        expectEqual(
            ScreenLocator.inferredNotchWidth(screenWidth: 1512, auxiliaryTopLeftAreaWidth: 0, safeAreaTop: 38),
            nil,
            "full-screen inferred width is rejected"
        )
    }

    test("notch rect is top centered with given width") {
        let info = screen(top: 38, notch: 200, main: true)
        let rect = ScreenLocator.notchRect(for: info, defaultWidth: 220)

        expectEqual(rect.width, 200, "real notch width wins")
        expectEqual(rect.height, 38, "safe area above minimum sets height")
        expectEqual(rect.midX, info.frame.midX, "notch is centered")
        expectEqual(rect.maxY, info.frame.maxY, "notch hugs the top edge")
    }

    test("notch rect uses default width when no notch") {
        let info = screen(top: 0, notch: nil, main: true)
        let rect = ScreenLocator.notchRect(for: info, defaultWidth: 220)

        expectEqual(rect.width, 220, "default notch width used")
        expectEqual(rect.height, 32, "minimum height used without safe area")
    }
}
