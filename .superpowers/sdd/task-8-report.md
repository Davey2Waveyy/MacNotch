# Task 8 Report

## Status

Implemented `NotchWindow` and a placeholder `NotchRootView` under `MacNotchKit`, then wired the window into `AppDelegate`.

## Changes

- Added `Sources/MacNotchKit/UI/NotchRootView.swift`
  - `NotchWindowModel` as an `ObservableObject` with `@Published isExpanded`
  - placeholder SwiftUI chrome for collapsed and expanded states
- Added `Sources/MacNotchKit/Window/NotchWindow.swift`
  - owns `NSPanel`, `NotchStateMachine`, and `NotchWindowModel`
  - syncs `model.isExpanded` from `machine.isExpanded`
  - schedules deterministic expand/collapse completion work without runaway timers
  - positions the panel from `ScreenLocator`
- Updated `Sources/MacNotchKit/App/AppDelegate.swift`
  - loads settings
  - creates and shows `NotchWindow`
  - wires menu bar toggle to `NotchWindow.toggle()`
- Added `Sources/MacNotchTests/NotchWindowTests.swift`
  - model default state coverage
  - root view construction coverage
  - `show()` activation coverage against enabled module ordering from persisted settings
- Updated `Sources/MacNotchTests/main.swift` to register the new tests

## Verification

- `swift build`
  - passed
- `swift run MacNotchTests`
  - passed
  - `57 checks, 0 failure(s)`

## Constraints Honored

- Production files were added under `Sources/MacNotchKit/...`
- `ScreenLocator` and `ScreenInfo` were left unchanged
- Current `NotchStateMachine` states and completion APIs were used instead of the stale brief sample

## Concerns

- `NotchWindow` currently reserves the expanded panel footprint up front and relies on SwiftUI to render the collapsed or expanded chrome inside it. That matches the requested simple deterministic behavior, but fine-grained hit-testing and a tighter collapsed hover zone are still Phase 2 work.
- The new tests cover construction and activation flow, but not live hover timing against AppKit events. That part is verified at compile/runtime level here and will still benefit from manual UI verification once GUI execution is appropriate.
