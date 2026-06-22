import MacNotchKit

func notchStateMachineTests() {
    test("hover enter starts expansion when enabled") {
        let sm = NotchStateMachine()
        expect(sm.hoverChanged(true), "hover returns changed")
        expectEqual(sm.state, .expanding, "state enters expanding")
        expect(sm.completeExpand(), "completion advances state")
        expectEqual(sm.state, .expanded, "state becomes expanded")
    }

    test("hover enter does nothing when disabled") {
        let sm = NotchStateMachine()
        sm.hoverToExpand = false
        expect(!sm.hoverChanged(true), "hover returns no change")
        expectEqual(sm.state, .collapsed, "state")
    }

    test("click toggles toward expanding and collapsing") {
        let sm = NotchStateMachine()
        expect(sm.clicked(), "first click changed")
        expectEqual(sm.state, .expanding, "first click starts expansion")
        expect(sm.completeExpand(), "expand completes")
        expectEqual(sm.state, .expanded, "expanded after completion")

        expect(sm.clicked(), "second click changed")
        expectEqual(sm.state, .collapsing, "second click starts collapse")
        expect(sm.completeCollapse(), "collapse completes")
        expectEqual(sm.state, .collapsed, "collapsed after completion")
    }

    test("mouse exit requests collapse and waits for completion") {
        let sm = NotchStateMachine()
        _ = sm.hoverChanged(true)
        _ = sm.completeExpand()

        expect(sm.mouseExitedPanel(), "exit changed")
        expectEqual(sm.state, .collapsing, "state enters collapsing")
        expect(sm.completeCollapse(), "collapse completion advances state")
        expectEqual(sm.state, .collapsed, "state becomes collapsed")
    }

    test("clicked outside collapses only from expanded states") {
        let sm = NotchStateMachine()
        expect(!sm.clickedOutside(), "no change when collapsed")
        _ = sm.clicked()
        _ = sm.completeExpand()

        expect(sm.clickedOutside(), "collapse requested when expanded")
        expectEqual(sm.state, .collapsing, "state waits in collapsing")
    }

    test("hover can reverse a pending collapse") {
        let sm = NotchStateMachine()
        _ = sm.hoverChanged(true)
        _ = sm.completeExpand()
        _ = sm.mouseExitedPanel()

        expect(sm.hoverChanged(true), "hover changes collapsing state")
        expectEqual(sm.state, .expanding, "hover re-enters expanding")
    }

    test("force collapse keeps a pending collapse on the close path") {
        let sm = NotchStateMachine()
        _ = sm.hoverChanged(true)
        _ = sm.completeExpand()
        _ = sm.mouseExitedPanel()

        expect(sm.forceCollapse(), "force collapse is accepted while already collapsing")
        expectEqual(sm.state, .collapsing, "state stays collapsing until completion")
        expect(sm.completeCollapse(), "forced collapse can complete")
        expectEqual(sm.state, .collapsed, "forced collapse finishes closed")
    }

    test("hover opens in compact mode") {
        let sm = NotchStateMachine()
        _ = sm.hoverChanged(true)
        expectEqual(sm.mode, .compact, "hover opens compact")
    }

    test("click opens in dashboard mode") {
        let sm = NotchStateMachine()
        _ = sm.clicked()
        expectEqual(sm.mode, .dashboard, "click opens dashboard")
    }

    test("hover exit does not collapse the dashboard") {
        let sm = NotchStateMachine()
        _ = sm.clicked()
        _ = sm.completeExpand()

        expect(!sm.mouseExitedPanel(), "hover exit is ignored in dashboard mode")
        expectEqual(sm.state, .expanded, "state stays expanded")
    }

    test("hover exit does not collapse the wide bar") {
        let sm = NotchStateMachine()
        _ = sm.clicked()
        _ = sm.completeExpand()
        _ = sm.switchMode(to: .wideBar)

        expect(!sm.mouseExitedPanel(), "hover exit is ignored in wide-bar mode")
        expectEqual(sm.state, .expanded, "state stays expanded")
    }

    test("outside click collapses any expanded mode") {
        let sm = NotchStateMachine()
        _ = sm.clicked()
        _ = sm.completeExpand()
        _ = sm.switchMode(to: .wideBar)

        expect(sm.clickedOutside(), "outside click collapses regardless of mode")
        expectEqual(sm.state, .collapsing, "state enters collapsing")
    }

    test("switchMode changes the active mode while expanded") {
        let sm = NotchStateMachine()
        _ = sm.clicked()
        _ = sm.completeExpand()

        expect(sm.switchMode(to: .wideBar), "switch reports change")
        expectEqual(sm.mode, .wideBar, "mode becomes wide bar")
        expect(!sm.switchMode(to: .wideBar), "no-op switch returns false")
    }

    test("switchMode is rejected when collapsed") {
        let sm = NotchStateMachine()
        expect(!sm.switchMode(to: .dashboard), "switch is rejected when collapsed")
        expectEqual(sm.mode, .compact, "mode is unchanged")
    }

    test("reopen during collapsing preserves the prior mode") {
        let sm = NotchStateMachine()
        _ = sm.hoverChanged(true)
        _ = sm.completeExpand()
        _ = sm.mouseExitedPanel()
        expectEqual(sm.state, .collapsing, "state is collapsing")

        expect(sm.clicked(), "click during collapse reopens")
        expectEqual(sm.mode, .compact, "prior compact mode is preserved on reopen")
    }
}
