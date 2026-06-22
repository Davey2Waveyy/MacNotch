# Task 11: Calendar module

## Summary

- Added `CalendarRefreshCoordinator` to manage the Calendar module's timer and block-based `NotificationCenter` observers for `EKEventStoreChanged` and `NSCalendarDayChanged`.
- Updated `CalendarModule.activate()` and `deactivate()` to use that coordinator so repeated activation is idempotent and block observer tokens are removed correctly on teardown.
- Verified `AppDelegate` already registers `CalendarModule` between `MediaModule` and `SystemModule`; no further order change was needed.
- Added harness tests covering Calendar refresh observer/timer idempotence, teardown, and callback wiring.

## Verification

- `swift build`
  - Pass
- `swift run MacNotchTests`
  - Pass: `156 checks, 0 failure(s)`

## Notes

- The existing Calendar formatting tests remained in place and passed in the full harness run.
