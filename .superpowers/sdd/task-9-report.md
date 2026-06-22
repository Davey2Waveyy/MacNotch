Status: complete

Commit:
- `b568ce0` - `Add System module (battery/CPU/RAM) with tested formatting`

Implemented:
- Added `SystemSample` with tested `batteryLabel`, `cpuLabel`, and `ramLabel` formatting.
- Added live `SystemSampler.sample()` for battery, charging state, CPU usage, and RAM usage.
- Added `SystemExpandedView` and `SystemModule`.
- Registered `SystemModule()` in `AppDelegate.registerModules()`.
- Added `systemSampleTests()` and registered it in the custom test harness.

Verification:
- `swift build` -> passed
- `swift run MacNotchTests` -> passed
- New formatting expectations verified:
  - battery with charging -> `84% ⚡`
  - no battery -> `—`
  - RAM `9_300_000_000` -> `9.3 GB`
  - CPU `12.6` -> `13%`

Concerns:
- CPU usage currently uses cumulative host CPU ticks since boot, which is coarse but compile-clean and sufficient for this task. A later refinement could compute a delta between samples for a more responsive live percentage.

---

Follow-up Fixes:
- Guarded battery percentage calculation behind a pure `batteryPercent(current:max:)` helper so `kIOPSMaxCapacityKey == 0` or a missing max now yields `nil` instead of dividing by zero or converting a non-finite value.
- Replaced lifetime-average CPU sampling with interval sampling from successive `host_cpu_load_info` snapshots. The live sampler now stores the previous snapshot behind a small lock-protected store, and a pure `cpuUsagePercent(previous:current:)` helper covers the delta math in tests.
- Added `NotchWindow.tearDown()` to deactivate only the modules activated by `show()`, made teardown idempotent, and canceled pending window transition callbacks during teardown. Wired `AppDelegate.applicationWillTerminate(_:)` to call that path.
- Preserved the existing `NotchWindow` reopen behavior during collapse animation while keeping collapse-grace toggle behavior unchanged.

Added Tests:
- `battery percent is unavailable when max capacity is zero`
- `cpu usage percent uses interval deltas between snapshots`
- `cpu usage percent returns zero for the first snapshot`
- `NotchWindow teardown deactivates modules it activated exactly once`
- Existing branch test kept green: `NotchWindow toggle during collapse animation reopens immediately`

Verification Output:
- `swift run MacNotchTests`
  - exit code: 0
  - result: `118 checks, 0 failure(s)`
- `swift build`
  - exit code: 0
  - result: `Build complete! (0.46s)`
