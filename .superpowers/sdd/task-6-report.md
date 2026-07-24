# Task 6 Report: Shared UI Primitives and Module State Views

## Files changed

- Created `Sources/MacNotchKit/UI/NotchControls.swift` — `NotchIconButton`, `NotchSegmentedControl`, `NotchFocusRing` (+ `View.notchFocusRing`), copied verbatim from the brief. Internal (non-public) access, consistent with every other type in `Sources/MacNotchKit/UI/` except `NotchRootView` and `NotchThemeTokens`.
- Created `Sources/MacNotchKit/UI/ModuleStateViews.swift` — `ModuleEmptyStateView`, `ModuleLoadingStateView`, `ModulePermissionStateView`, `ModuleErrorStateView`, copied verbatim from the brief.
- Modified `Sources/MacNotchKit/UI/DashboardLayoutView.swift`:
  - `navArrow(systemName:enabled:action:)` now builds on `NotchIconButton` with accessibility labels "Previous dashboard page" / "Next dashboard page", exactly as prescribed. Preserved the pre-existing "invisible when disabled" look by keeping `.opacity(enabled ? 1 : 0)` instead of the brief's literal snippet (which would leave a visible-but-disabled arrow) — this follows the higher-priority instruction to preserve existing behavior exactly.
  - Removed the now-dead `arrowWidth` constant (was only used by the old inline arrow view, unused after the refactor).
  - Header lock/pin button: left the existing custom pill-background + pin-state tint styling untouched (a genuine visual difference from `NotchIconButton`'s plain 30x30 icon, not just an accessibility gap) and instead added `.accessibilityLabel` / `.help` ("Unpin notch panel" / "Pin notch panel") for parity with the compact footer button, without restyling.
- Modified `Sources/MacNotchKit/UI/NotchRootView.swift`:
  - Compact footer pin button: added `.accessibilityLabel(model.isPinned ? "Unpin notch panel" : "Pin notch panel")` and matching `.help(...)`, per the brief's exact snippet.
  - Compact footer "Dashboard" button: added `.accessibilityLabel("Open dashboard")` and `.help("Open dashboard")` (not given verbatim in the brief, but required by the brief's own manual-check step, which expects the compact dashboard button to remain distinguishable/labeled after this task).

## Where primitives were NOT adopted, and why

- `Sources/MacNotchKit/Modules/QuickToggles/QuickTogglesViews.swift` — unchanged. `ToggleChip` is icon+text with on/off tinting, not an icon-only control, so it is not a drop-in match for `NotchIconButton`.
- `Sources/MacNotchKit/Modules/Timers/TimersViews.swift` — unchanged. The only icon-only candidate is `stepButton` (minus/plus stepper in `customRow`), but it uses a background-filled 20x20 square, whereas `NotchIconButton` is a plain (no background) 30x30 hit target. Swapping in `NotchIconButton` would enlarge/restyle the stepper beyond a clean drop-in and risk breaking the tight `customRow` layout — out of scope per "do not restyle or refactor beyond that."
- `Sources/MacNotchKit/Modules/Shelf/ShelfViews.swift` — unchanged. No icon-only buttons exist; all shelf controls are chips (icon+text) or context-menu items.

All three module files were read in full before making this decision; no edits were made to them. `git status` after the edits confirms they remain untouched.

## Test / build output

- `swift build`: clean, `Build complete!` (verified again after removing the dead `arrowWidth` constant).
- `swift run MacNotchTests`: **348 checks, 0 failure(s)**. No new test file was added — out of scope for this task; verification is tests-still-pass plus the manual GUI check below.

## Manual GUI check

Skipped per instructions — did not run `make run` / launch the app. Verified only via `swift build` + the full test suite. **The brief's Step 4 manual smoke check (hover each icon button and confirm help text appears; confirm arrow/pin/dashboard buttons still work) is outstanding and should be logged as manual-verify-outstanding in the ledger.**

## Self-review

- New files match the brief's Step 1 / Step 2 code exactly, character-for-character.
- Step 3 deviates from the literal snippet in one place (nav-arrow opacity-when-disabled) to honor the higher-priority instruction to preserve existing behavior exactly; documented above.
- Chose not to force `NotchIconButton` onto the `DashboardLayoutView` header lock button since it has state-dependent styling (pill background, pin-state tint) outside `NotchIconButton`'s contract — added accessibility metadata only, matching how the brief treats the `NotchRootView` compact footer buttons (labels only, no restyle).
- Confirmed via `git status` that only the four intended files are staged; unrelated pre-existing uncommitted changes (`website/`, `.agents/`, docs plans, `skills-lock.json`) were left alone.
- Build and full test suite are clean after all edits, including after removing the dead `arrowWidth` constant.
- This file replaces a stale `task-6-report.md` left over from an earlier task-numbering scheme (previously documented the AppKit menu-bar bootstrap work); that content is now superseded by this task's actual scope.

## Final-review fix

The sprint review flagged that adopting `NotchIconButton` for the dashboard nav arrows silently changed their visuals: they went from 20x20 / 10pt / `.white.opacity(0.55)` to `NotchIconButton`'s default 30x30 / 12pt / full-brightness. Task 6 was meant to be a behavior-preserving refactor, so this restores the original look:

- `Sources/MacNotchKit/UI/NotchControls.swift`: `NotchIconButton` gained two optional parameters, `size: CGFloat = 30` and `iconSize: CGFloat = 12`, defaulting to the prior hardcoded values so every other call site (none currently exist elsewhere) is unaffected.
- `Sources/MacNotchKit/UI/DashboardLayoutView.swift`: the `navArrow` call site now passes `size: 20, iconSize: 10` and applies `.foregroundStyle(.white.opacity(0.55))`, matching the pre-Task-6 rendering exactly. The `.opacity(enabled ? 1 : 0)` disabled-invisibility behavior was left untouched.
- No other call sites were touched; `grep -rn "NotchIconButton("` across `Sources/` confirms `DashboardLayoutView.swift` is the only usage, so the pin button (which doesn't use `NotchIconButton`) was unaffected.

### Test output tail

```
• timer refresh policy wakes at expiry when it comes before the next display boundary
  ✓ near-expiry countdown wakes at the exact firing boundary

348 checks, 0 failure(s)
```

`swift build` completed with `Build complete!` and no warnings/errors. Commit: `1c0b614` — "fix: restore original dashboard nav arrow size and tint".
