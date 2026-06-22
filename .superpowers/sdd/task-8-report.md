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

---

## Task 8 Fix Follow-up (2026-06-22)

### Fix Details

- Added `Sources/MacNotchKit/Window/NotchWindowTransitionCoordinator.swift` as a small pure coordinator for visual transition state.
  - Keeps the UI visually expanded during hover-driven collapse grace.
  - Separates `collapseGrace` from `collapseAnimation` so the window starts visual collapse only after the grace delay.
  - Lets stale scheduled callbacks no-op after hover re-entry or other state changes.
- Updated `Sources/MacNotchKit/Window/NotchWindow.swift`.
  - Hover exit now requests a graceful collapse path.
  - Click/toggle collapse uses the immediate animation path.
  - `sync()` now derives `model.isExpanded` from the coordinator instead of directly mirroring `machine.isExpanded`.
  - After grace expires, the window starts the visual collapse animation; after that animation expires, it calls `machine.completeCollapse()` and re-syncs.
- Updated `Sources/MacNotchKit/UI/NotchRootView.swift`.
  - Replaced opacity-only switching with a low-risk size/corner-radius/content scale transition inside the fixed footprint.
- Extended `Sources/MacNotchTests/NotchWindowTests.swift`.
  - Covers visual-expanded state during collapse grace.
  - Covers hover re-entry canceling pending collapse.
  - Covers immediate-collapse/toggle synchronization staying coherent.

### Verification Output

- `swift build`
  - passed
  - `Build complete! (0.43s)`
- `swift run MacNotchTests`
  - passed
  - `70 checks, 0 failure(s)`

---

## Task 8 Final Review Fixes (2026-06-22)

### Fix Details

- Updated `Sources/MacNotchKit/Window/NotchWindow.swift`.
  - The panel now resizes and re-centers around the notch as visual state changes instead of permanently keeping the expanded footprint.
  - Collapsed state uses the actual notch rect size for both visuals and hit-testing.
  - Collapse grace keeps the expanded footprint until the grace delay elapses, then switches to the collapsed footprint when visual collapse starts.
  - Replaced the `DispatchWorkItem` callback path with token-based main-queue scheduling so stale grace and collapse callbacks no-op cleanly after re-entry or other state changes.
- Updated `Sources/MacNotchKit/UI/NotchRootView.swift`.
  - The SwiftUI host view now matches the current visual footprint instead of always laying out at expanded size, so the collapsed panel renders inside the same reduced bounds the `NSPanel` uses for hit-testing.
- Extended `Sources/MacNotchTests/NotchWindowTests.swift`.
  - Added direct `NotchWindow` regression coverage for collapsed frame sizing.
  - Added live scheduling coverage for grace-delayed collapse.
  - Added cancellation coverage proving hover re-entry prevents stale grace and stale collapse-completion callbacks from mutating the window after cancellation.

### Verification Output

- `swift build`
  - passed
  - `Build complete! (0.42s)`
- `swift run MacNotchTests`
  - passed
  - `89 checks, 0 failure(s)`
