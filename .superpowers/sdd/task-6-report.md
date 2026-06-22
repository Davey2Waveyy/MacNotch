# Task 6 Report

## Status

Implemented the AppKit agent bootstrap and menu bar controller for MacNotch using the split `MacNotchKit` library plus `MacNotch` executable layout from the Task 6 brief.

## Files

- `Sources/MacNotchKit/App/MenuBarController.swift`
- `Sources/MacNotchKit/App/AppDelegate.swift`
- `Sources/MacNotchKit/App/MacNotchApp.swift`
- `Sources/MacNotch/main.swift`
- `Sources/MacNotchTests/MacNotchAppTests.swift`
- `Sources/MacNotchTests/main.swift`

## Build Result

- `swift build`: passed

## Test Result

- `swift run MacNotchTests`: passed
- Checks: 39
- Failures: 0

## Notes

- `Sources/MacNotch/main.swift` now imports `MacNotchKit` and enters the agent bootstrap via `MacNotchApp.run()`.
- The Swift 6 top-level main-actor isolation issue is handled with `MainActor.assumeIsolated { MacNotchApp.run() }` to preserve the brief's `@MainActor public static func run()` API.
- `MenuBarController` exposes `onOpenSettings` and `onToggleNotch` callbacks and installs the required status menu items.

## Concerns

- Manual GUI verification via `make run` was not performed here, per the task note to leave that as manual verification for the user.
- There is no automated runtime test for the actual status-bar menu because the brief keeps the AppKit controller types internal and the public entrypoint starts the app event loop.

## Review Fix Addendum

- `Sources/MacNotchKit/App/MacNotchApp.swift`: replaced the local `AppDelegate` variable with private static storage so the delegate is strongly retained for the full app lifetime before `NSApplication.run()`.
- `Sources/MacNotch/main.swift`: replaced `MainActor.assumeIsolated` top-level startup with a thin `@main` executable type whose `@MainActor static func main()` calls `MacNotchApp.run()`.
- `Sources/MacNotchTests/MacNotchAppTests.swift`: no change required. The existing compile-time test still verifies the public `@MainActor` `MacNotchApp.run` entrypoint without starting the event loop.

## Review Fix Verification

- `swift build`: passed
- `swift run MacNotchTests`: passed
- Checks: 45
- Failures: 0
