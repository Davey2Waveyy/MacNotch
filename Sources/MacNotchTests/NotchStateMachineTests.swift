import MacNotchKit

func notchStateMachineTests() {
    test("hover enter expands when enabled") {
        let sm = NotchStateMachine()
        expect(sm.hoverChanged(true), "hover returns changed")
        expectEqual(sm.state, .expanded, "state")
    }
    test("hover enter does nothing when disabled") {
        let sm = NotchStateMachine()
        sm.hoverToExpand = false
        expect(!sm.hoverChanged(true), "hover returns no change")
        expectEqual(sm.state, .collapsed, "state")
    }
    test("click toggles both ways") {
        let sm = NotchStateMachine()
        expect(sm.clicked(), "first click changed"); expectEqual(sm.state, .expanded, "expanded")
        expect(sm.clicked(), "second click changed"); expectEqual(sm.state, .collapsed, "collapsed")
    }
    test("mouse exit collapses") {
        let sm = NotchStateMachine()
        _ = sm.clicked()
        expect(sm.mouseExitedPanel(), "exit changed")
        expectEqual(sm.state, .collapsed, "state")
    }
    test("clicked outside collapses only when expanded") {
        let sm = NotchStateMachine()
        expect(!sm.clickedOutside(), "no change when collapsed")
        _ = sm.clicked()
        expect(sm.clickedOutside(), "collapses when expanded")
        expectEqual(sm.state, .collapsed, "state")
    }
}
