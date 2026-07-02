# Task 3 Report: Application Support Migration

## What you implemented

- Added `AppDataLocations` to centralize current and legacy Application Support paths using `NotchBrand.applicationSupportDirectoryName` and `NotchBrand.legacyApplicationSupportDirectoryName`.
- Added `AppDataMigrator` with `migrateIfNeeded()` to:
  - no-op when the migration marker already exists
  - copy legacy files from `Application Support/MacNotch` into `Application Support/NotchApple` without overwriting existing destination files
  - write `.macnotch-migrated` after successful migration or when no legacy directory exists
  - log and return `false` on migration or marker-write failure
- Pointed persisted store defaults at `Application Support/NotchApple` for:
  - settings
  - shelf
  - code projects
  - launcher
  - reminders
  - clipboard
  - screen time
- Updated `AppDelegate.applicationDidFinishLaunching` to run migration before `settings.load()`.
- Added `AppDataMigratorTests` and registered them in the test runner.

## What you tested and test results

- Ran full test suite: `swift run MacNotchTests`
- Result: pass, `327 checks, 0 failure(s)`
- Verified new migration coverage:
  - `AppDataLocations` derives `NotchApple` and `MacNotch` support directories
  - migration copies legacy data once
  - migration writes the marker
  - repeat migration does not overwrite current data

## TDD Evidence: RED and GREEN commands/output summaries

- RED: `swift run MacNotchTests`
  - Result: failed at compile time as expected
  - Summary: `AppDataMigratorTests.swift` could not find `AppDataLocations` or `AppDataMigrator` in scope
- GREEN: `swift run MacNotchTests`
  - Result: passed
  - Summary: full suite completed with `327 checks, 0 failure(s)`

## Files changed

- `Sources/MacNotchKit/App/AppDataLocations.swift`
- `Sources/MacNotchKit/App/AppDataMigrator.swift`
- `Sources/MacNotchKit/App/SettingsStore.swift`
- `Sources/MacNotchKit/App/AppDelegate.swift`
- `Sources/MacNotchKit/Modules/Shelf/ShelfStore.swift`
- `Sources/MacNotchKit/Modules/Code/CodeProjectStore.swift`
- `Sources/MacNotchKit/Modules/Launcher/LauncherStore.swift`
- `Sources/MacNotchKit/Modules/Reminders/RemindersStore.swift`
- `Sources/MacNotchKit/Modules/Clipboard/ClipboardStore.swift`
- `Sources/MacNotchKit/Modules/ScreenTime/ScreenTimeModule.swift`
- `Sources/MacNotchTests/AppDataMigratorTests.swift`
- `Sources/MacNotchTests/main.swift`

## Self-review findings

- Implementation matches the Task 3 brief file-for-file and behavior-for-behavior.
- Migration is intentionally shallow-copy only, which matches the brief and preserves current files on repeat runs.
- Commit scope is limited to Task 3 source/test files; unrelated dirty and untracked workspace files were not staged or modified.

## Concerns

- None.

## Follow-up fix: review findings

### What changed

- Restored parent-directory creation before writes in the reviewed persistence paths:
  - `ClipboardStore.save()`
  - `LauncherStore.save()`
  - `RemindersStore.save()`
  - `ScreenTimeModule.saveSwitchCount()`
- Added regression coverage for fresh-filesystem writes in:
  - `ClipboardStore`
  - `RemindersStore`
- Added migration coverage proving an existing destination file is preserved on first migration when no marker exists yet.

### TDD evidence for follow-up

- RED: `swift run MacNotchTests`
  - Result: failed
  - Summary: new persistence tests failed because clipboard and reminders data were not written when the parent directory did not already exist; run ended with `333 checks, 2 failure(s)`
- GREEN: `swift run MacNotchTests`
  - Result: passed
  - Summary: full suite completed with `333 checks, 0 failure(s)`

### Follow-up files changed

- `Sources/MacNotchKit/Modules/Clipboard/ClipboardStore.swift`
- `Sources/MacNotchKit/Modules/Launcher/LauncherStore.swift`
- `Sources/MacNotchKit/Modules/Reminders/RemindersStore.swift`
- `Sources/MacNotchKit/Modules/ScreenTime/ScreenTimeModule.swift`
- `Sources/MacNotchTests/AppDataMigratorTests.swift`
- `Sources/MacNotchTests/AppDataPersistenceTests.swift`
- `Sources/MacNotchTests/main.swift`

### Test output summary

- `swift run MacNotchTests` passed with `333 checks, 0 failure(s)`
