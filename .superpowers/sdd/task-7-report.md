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

## Task 7 Review Fixes

- Updated [ScreenLocator.swift](/Users/davey/MyProjects/MacNotch/Sources/MacNotchKit/Window/ScreenLocator.swift) so `current()` now delegates notch-width inference to a package-scoped helper that returns `nil` unless:
  - `safeAreaTop > 0`
  - `auxiliaryTopLeftArea` is present
  - the computed width is positive
  - the computed width is smaller than the full screen width
- This removes the bad fallback where a missing `auxiliaryTopLeftArea` could manufacture a full-screen-width notch and lets `notchRect(for:defaultWidth:)` fall back to `defaultWidth` instead.
- Expanded [ScreenLocatorTests.swift](/Users/davey/MyProjects/MacNotch/Sources/MacNotchTests/ScreenLocatorTests.swift) coverage to assert:
  - `choose(from:)` falls back to the first screen when there is no notch and no main screen
  - inferred notch width is rejected when `auxiliaryTopLeftArea` is missing or produces a full-screen result
  - `notchRect(for:defaultWidth:)` uses `max(safeAreaTop, 32)` for height both above the minimum and at the default minimum

## Task 7 Review Verification

- `swift run MacNotchTests` — passed, `51 checks, 0 failure(s)`
- `swift build` — passed
