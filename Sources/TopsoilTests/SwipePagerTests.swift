import TopsoilKit

func swipePagerTests() {
    test("trackpad swipe turns one page per gesture") {
        var pager = SwipePager()
        // Swipe left (content moves left, negative dx) → next page (+1).
        _ = pager.feed(dx: -10, dy: 0, began: true, ended: false, isMomentum: false, isGesture: true)
        expectEqual(pager.feed(dx: -20, dy: 0, began: false, ended: false, isMomentum: false, isGesture: true), 1, "crosses threshold → next")
        expect(pager.feed(dx: -20, dy: 0, began: false, ended: false, isMomentum: false, isGesture: true) == nil, "no second turn in same gesture")
        // A fresh gesture can turn again.
        expectEqual(pager.feed(dx: 40, dy: 0, began: true, ended: false, isMomentum: false, isGesture: true), -1, "new gesture, swipe right → prev")
        _ = pager.feed(dx: 0, dy: 0, began: false, ended: true, isMomentum: false, isGesture: true)
    }
    test("vertical-dominant scroll never turns a page") {
        var pager = SwipePager()
        _ = pager.feed(dx: 10, dy: 60, began: true, ended: false, isMomentum: false, isGesture: true)
        expect(pager.feed(dx: 10, dy: 60, began: false, ended: false, isMomentum: false, isGesture: true) == nil, "vertical scroll ignored")
    }
    test("momentum phase never turns a page") {
        var pager = SwipePager()
        _ = pager.feed(dx: 10, dy: 0, began: true, ended: false, isMomentum: false, isGesture: true)
        expect(pager.feed(dx: 40, dy: 0, began: false, ended: false, isMomentum: true, isGesture: true) == nil, "coasting momentum ignored")
    }
    test("mouse wheel rearms per detent") {
        var pager = SwipePager()
        expectEqual(pager.feed(dx: 30, dy: 0, began: false, ended: false, isMomentum: false, isGesture: false), -1, "first detent")
        expectEqual(pager.feed(dx: 30, dy: 0, began: false, ended: false, isMomentum: false, isGesture: false), -1, "second detent turns again")
    }
}
