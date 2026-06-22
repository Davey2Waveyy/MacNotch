# Task 7 Report

## Status

Complete.

## Changes

- Added [ScreenInfo.swift](/Users/davey/MyProjects/MacNotch/Sources/MacNotchKit/Window/ScreenInfo.swift) with `frame`, `safeAreaTop`, `notchWidth`, `isMain`, and derived `hasNotch`.
- Added [ScreenLocator.swift](/Users/davey/MyProjects/MacNotch/Sources/MacNotchKit/Window/ScreenLocator.swift) with:
  - `choose(from:)` preferring notched, then main, then first screen
  - `notchRect(for:defaultWidth:)` using real notch width when present and `max(safeAreaTop, 32)` for height
  - `current()` mapping live `NSScreen` geometry into `ScreenInfo`
- Added [ScreenLocatorTests.swift](/Users/davey/MyProjects/MacNotch/Sources/MacNotchTests/ScreenLocatorTests.swift) using the custom harness.
- Registered `screenLocatorTests()` in [main.swift](/Users/davey/MyProjects/MacNotch/Sources/MacNotchTests/main.swift).

## Verification

- `swift run MacNotchTests` — passed, `45 checks, 0 failure(s)`
- `swift build` — passed

## Concerns

- `current()` derives `notchWidth` from `NSScreen.auxiliaryTopLeftArea` per the plan/spec. That path compiles and matches the requested behavior, but it is only covered indirectly here because the harness does not exercise live `NSScreen` state.
