import Foundation
import MacNotchKit

func calendarModuleTests() {
    final class FakeTimer: CalendarRefreshTimer {
        private(set) var invalidateCount = 0

        func invalidate() {
            invalidateCount += 1
        }
    }

    test("calendar: refresh coordinator activates observers and timer once") {
        var observedNames: [Notification.Name] = []
        var timerCount = 0

        let coordinator = CalendarRefreshCoordinator(
            addObserver: { name, _ in
                observedNames.append(name)
                return NSObject()
            },
            removeObserver: { _ in },
            makeTimer: { _ in
                timerCount += 1
                return FakeTimer()
            }
        )

        coordinator.activate(refresh: {})
        coordinator.activate(refresh: {})

        expectEqual(observedNames, [.EKEventStoreChanged, .NSCalendarDayChanged], "observers added once in expected order")
        expectEqual(timerCount, 1, "timer created once")
    }

    test("calendar: refresh coordinator removes observer tokens and invalidates timer once") {
        var removedTokens: [NSObjectProtocol] = []
        let timer = FakeTimer()

        let coordinator = CalendarRefreshCoordinator(
            addObserver: { _, _ in NSObject() },
            removeObserver: { token in removedTokens.append(token) },
            makeTimer: { _ in timer }
        )

        coordinator.activate(refresh: {})
        coordinator.deactivate()
        coordinator.deactivate()

        expectEqual(removedTokens.count, 2, "each observer token removed once")
        expectEqual(timer.invalidateCount, 1, "timer invalidated once")
    }

    test("calendar: refresh coordinator forwards notification and timer refresh callbacks") {
        var observerActions: [() -> Void] = []
        var timerAction: (() -> Void)?
        var refreshCount = 0

        let coordinator = CalendarRefreshCoordinator(
            addObserver: { _, action in
                observerActions.append(action)
                return NSObject()
            },
            removeObserver: { _ in },
            makeTimer: { action in
                timerAction = action
                return FakeTimer()
            }
        )

        coordinator.activate {
            refreshCount += 1
        }

        observerActions.forEach { $0() }
        timerAction?()

        expectEqual(refreshCount, 3, "all refresh triggers reuse the same callback")
    }
}
