# MacNotch — Phase 1 Design (The Notch Shell + Starter Modules)

**Date:** 2026-06-22
**Status:** Approved (design), pending implementation plan
**Author:** davey (with Claude)

A personal, native macOS recreation of [macnotch.io](https://macnotch.io): a modular
productivity dashboard that lives in the MacBook notch. This document specifies
**Phase 1 only** — the foundational notch shell plus four starter modules. Later
modules (GitHub, weather, Pomodoro, translation, Bluetooth, AI coding, etc.) are
out of scope here and will each get their own spec.

---

## 1. Goals

- A borderless, always-on-top window that hugs the physical notch.
- Two states: **collapsed** (a thin live glance hugging the notch) and **expanded**
  (a panel that spring-drops into a vertical stack of modules), with a smooth
  animated transition triggered by hover and click.
- A clean **module plugin architecture** (`NotchModule`) so Phase 2 modules are
  drop-in additions, not rewrites. This is the load-bearing abstraction.
- Four working starter modules: **Now Playing**, **Calendar**, **Battery/System**,
  and a drag-and-drop **Drop Shelf**.
- A menu-bar agent app (no Dock icon) with a settings window to enable/disable and
  reorder modules, plus launch-at-login.
- Buildable with **Swift Package Manager only** (no Xcode), packaged into a
  `.app` bundle by a script, ad-hoc signed for personal/local use.

## 2. Non-goals (explicitly deferred)

- Any module beyond the four above (GitHub, weather, Pomodoro, notifications,
  translation, Bluetooth, AirDrop/zip/convert drop *actions*, AI coding).
- Multi-display support beyond "primary screen with a notch." (Designed not to
  crash on non-notch / external displays, but not a target experience.)
- App Store distribution, notarization, sandboxing, auto-update.
- Universal system-wide media that *requires* private entitlements Apple withholds.
- Theming/skins, localization.

## 3. Constraints & environment

- **macOS 26.5 (Tahoe), Apple Silicon (arm64).**
- **Swift 6.3**, Command Line Tools only — **no full Xcode** (`xcodebuild`
  unavailable). All UI is built in code; bundle assembly is scripted.
- **Distribution:** personal/local only. Ad-hoc codesign (`codesign -s -`). No
  notarization. App runs from `/Applications` (or `~/Applications`).
- **macOS 15.4+ media restriction:** the private `MediaRemote` framework no longer
  reliably returns system-wide now-playing info to third-party apps. The media
  module is designed around this (see §5.1).

## 4. Architecture

### 4.1 Component map

```
AppCore (LSUIElement agent)
├── SettingsStore         enable/disable + order of modules, persisted (UserDefaults/JSON)
├── LoginItem             launch-at-login via SMAppService
├── MenuBarController      status item: open settings, quit, toggle notch
└── NotchWindow (AppKit NSPanel)
    ├── NotchStateMachine  collapsed ↔ expanded, hover/click, spring animation
    ├── ScreenLocator      finds notch frame via NSScreen.safeAreaInsets / auxiliaryTopLeftArea
    └── NSHostingView → NotchRootView (SwiftUI)
        └── ModuleStack    renders enabled modules in order
            ├── MediaModule      : NotchModule
            ├── CalendarModule   : NotchModule
            ├── SystemModule     : NotchModule
            └── ShelfModule      : NotchModule
```

Each unit has one purpose and a defined interface:
- `NotchWindow` knows window geometry and state; it knows nothing about module internals.
- `ModuleStack` knows ordering and enable/disable; it talks to modules only through `NotchModule`.
- A module knows its own data source and its two views; it knows nothing about the window.

### 4.2 The `NotchModule` protocol (the seam)

```swift
protocol NotchModule: AnyObject, Identifiable {
    var id: String { get }                 // stable key for settings/order
    var title: String { get }              // shown in settings
    var isEnabled: Bool { get set }

    // SwiftUI views. Collapsed = thin glance (optional); expanded = full card.
    @MainActor func collapsedView() -> AnyView?   // nil = nothing in collapsed bar
    @MainActor func expandedView() -> AnyView

    // Lifecycle
    func activate()        // start observers/timers when shown
    func deactivate()      // stop them when hidden / disabled
    func refresh() async   // pull latest data on demand (e.g. on expand)
}
```

- Modules are `ObservableObject`s internally; their views observe their own state.
- The shell calls `activate()`/`deactivate()` around visibility and enable/disable.
- `refresh()` is called when the panel expands (and on a per-module cadence if the
  module wants one — the module owns its own timer, the shell does not poll).

### 4.3 State machine & animation

States: `.collapsed`, `.expanding`, `.expanded`, `.collapsing`.

Triggers:
- **Hover** over the notch hot-zone → expand (configurable; default on).
- **Click** the notch → toggle.
- **Mouse exits** the expanded panel bounds (with a short grace delay, ~0.25s) → collapse.
- **Click outside** → collapse.

Animation: SwiftUI `.spring(response: 0.35, dampingFraction: 0.78)` on the panel's
height/opacity; the `NSPanel` frame is resized to the maximum (expanded) size up
front and the SwiftUI content animates within it, so AppKit window resizing never
fights the spring. Hot-zone tracking uses an `NSTrackingArea` sized to the
collapsed notch; the expanded bounds are tracked by the SwiftUI panel via a
hover/`onContinuousHover` + a global mouse-moved monitor for exit detection.

### 4.4 Window & notch positioning

- `ScreenLocator` picks the screen whose `safeAreaInsets.top > 0` (has a notch);
  falls back to `NSScreen.main`. The notch width is derived from
  `screen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea` when available, else a
  sensible default (~200pt) centered.
- `NotchWindow` is an `NSPanel`: `styleMask = [.borderless, .nonactivatingPanel]`,
  `level = .statusBar + 1`, `isFloatingPanel = true`, `collectionBehavior =
  [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]`, `backgroundColor =
  .clear`, `hasShadow = false` (shadow drawn by SwiftUI on the expanded panel only).
- Frame origin = top-center of the chosen screen, anchored under the menu bar so
  the collapsed black shape visually merges with the physical notch.
- **No-notch fallback:** if no screen reports a notch, render a "virtual notch" of
  the default width at the top-center of the main screen. The app must not crash;
  it simply draws its own notch shape.

## 5. Modules (Phase 1)

### 5.1 Media — Now Playing

**Purpose:** show current track and offer transport controls.

**Data source — `MediaSource` protocol** (the per-app-vs-universal hedge):

```swift
protocol MediaSource {
    var isAvailable: Bool { get }
    func nowPlaying() -> NowPlaying?     // title, artist, album, artwork, isPlaying, elapsed/duration, app
    func playPause(); func next(); func previous()
}
```

Implementations, aggregated by a `MediaController` that picks the active source:
- **`AppleScriptSource` (primary, reliable):** ScriptingBridge/AppleScript to
  `Music.app` and `Spotify.app`. Reads track info + playerState; sends
  playpause/next/previous. Entitlement-free, works on macOS 26. Requires Automation
  permission per target app.
- **`MediaRemoteSource` (opportunistic):** attempts private `MediaRemote`
  (`MRMediaRemoteGetNowPlayingInfo`). If it returns nothing (expected on 26.x),
  `isAvailable` is false and it's skipped. No hard dependency; pure upside.

`MediaController` selection order: a source reporting `isPlaying` wins; ties broken
by MediaRemote > Music > Spotify (configurable later). Artwork fetched from the
source; cached. Polls active source every ~1s while expanded, ~2s while collapsed
(only if a track exists).

**Collapsed view:** small album thumb + animated equalizer when playing (the live
glance to the left of the notch). Nothing when nothing is playing.
**Expanded view:** artwork, title, artist/app, scrubber (read-only progress in P1),
prev/playpause/next.
**Permissions:** Automation (Music, Spotify) — prompted on first control.
**Risks:** AppleScript latency; apps not running (handle gracefully → source
unavailable). MediaRemote may be fully dead — acceptable, it's the hedge.

### 5.2 Calendar

**Purpose:** today's date + upcoming events at a glance.
**Data source:** EventKit (`EKEventStore`), events for `startOfDay…endOfDay`.
**Collapsed view:** none in P1 (clock is provided by the shell's menu-bar-adjacent
time; calendar contributes only in expanded). *(If desired, a "next event in Nm"
glance is a trivial later add.)*
**Expanded view:** "Mon, Jun 22" header + up to ~4 upcoming events (time + title,
colored dot from calendar color).
**Permissions:** Calendar (`requestFullAccessToEvents` on macOS 14+).
**Refresh:** on expand + `EKEventStoreChanged` notification.
**Edge cases:** access denied → card shows a "Grant Calendar access" affordance
that opens System Settings. No events → "Nothing left today."

### 5.3 Battery / System

**Purpose:** the zero-dependency canary that proves the module API end to end.
**Data source:** IOKit `IOPSCopyPowerSourcesInfo` (battery %, charging, time
remaining); `host_statistics64` / `host_processor_info` for CPU; `vm_statistics64`
for memory. Desktop Macs (no battery) → hide battery row, still show CPU/RAM.
**Collapsed view:** none in P1.
**Expanded view:** battery glyph + % + charging bolt; CPU % and RAM used.
**Permissions:** none.
**Refresh:** module-owned timer, ~3s while expanded; paused while collapsed.

### 5.4 Drop Shelf

**Purpose:** drag files/folders onto the notch; they park in a tray; drag them back
out elsewhere. (MacNotch's "Drop" feature — kept simple in P1: a holding shelf, not
the AirDrop/zip/convert *actions*, which are Phase 2.)

**Behavior:**
- The expanded panel is an `NSView` drag destination
  (`registerForDraggedTypes([.fileURL])`). On drop, each URL is recorded as a
  **security-scoped bookmark** and a copy/reference is tracked in a `ShelfStore`
  (persisted across launches). Files themselves are *not* moved; the shelf holds
  references (plus cached thumbnail + name).
- Drag **out:** each shelf chip is a drag source providing the original file URL via
  `NSItemProvider`, so the user can drag into Finder, Mail, etc.
- Remove a chip via a small ✕ on hover; "Clear shelf" in settings.

**Collapsed view:** a small badge with item count when the shelf is non-empty.
**Expanded view:** horizontal row of file chips (icon + truncated name), as in the mockup.
**Permissions:** none beyond the bookmarks the user explicitly drops.
**Edge cases:** a bookmarked file later moved/deleted → chip marked stale, offers
removal. Directories allowed (folder icon).

## 6. App shell, settings, launch-at-login

- **Agent app:** `Info.plist` `LSUIElement = true` → no Dock icon. A menu-bar
  `NSStatusItem` provides: Open Settings, Toggle Notch, Quit.
- **Settings window** (SwiftUI): list of modules with enable toggles and drag-to-
  reorder; "Launch at login" toggle; per-module simple options (e.g. media source
  preference, max calendar events). Persisted in `SettingsStore`
  (Codable → `UserDefaults` or a JSON file in Application Support).
- **Launch at login:** `SMAppService.mainApp.register()` / `unregister()`.

## 7. Build & packaging (no Xcode)

- **`Package.swift`:** one executable target `MacNotch` (+ unit-test target).
  Platform `.macOS(.v14)` (min), built and run on 26.
- **`Scripts/package-app.sh`:**
  1. `swift build -c release`.
  2. Assemble `MacNotch.app/Contents/{MacOS,Resources}`.
  3. Write `Info.plist` (bundle id `io.local.macnotch`, `LSUIElement`, usage strings
     for Calendar + Automation, `LSMinimumSystemVersion 14.0`).
  4. Copy the built binary + any resources (assets).
  5. `codesign --force --deep --sign - --entitlements MacNotch.entitlements MacNotch.app`.
- **`MacNotch.entitlements`:** minimal — Apple Events automation for Music/Spotify;
  no sandbox (personal local build).
- **`make run` / `Scripts/run.sh`:** package then `open MacNotch.app`.
- **Re-signing note:** ad-hoc signature changes each build can re-trigger TCC
  prompts. Acceptable for personal use; documented in README. (Optional later: a
  stable self-signed cert to keep TCC grants sticky.)

## 8. Permissions & TCC summary

| Capability        | API                | When prompted              | If denied                          |
|-------------------|--------------------|----------------------------|------------------------------------|
| Calendar          | EventKit           | first Calendar expand      | card shows "Grant access" → Settings |
| Automation: Music | AppleScript        | first media control/read   | source unavailable, hidden          |
| Automation: Spotify | AppleScript      | first media control/read   | source unavailable, hidden          |
| Battery/CPU/RAM   | IOKit/host_*       | never                      | n/a                                 |
| Drop Shelf        | security bookmarks | n/a (user-initiated drop)  | n/a                                 |

## 9. Error handling & resilience

- Every external read (AppleScript, EventKit, IOKit) is failable and returns a
  typed empty/unavailable state; a failing module renders a quiet placeholder and
  never crashes the shell.
- A module throwing/timing out is isolated by `ModuleStack` (one bad module ≠ dead
  notch).
- No screen / no notch → virtual notch fallback (§4.4).
- AppleScript timeouts bounded (~1.5s) so the UI never blocks.

## 10. Testing strategy

- **Unit-testable, isolated units** (no AppKit needed):
  - `MediaController` source-selection logic (inject fake `MediaSource`s).
  - `SettingsStore` encode/decode + module ordering.
  - `ShelfStore` bookmark add/remove/stale detection (temp files).
  - `SystemModule` parsing of sampled IOKit/host structs (inject raw samples).
  - `NotchStateMachine` transitions (pure state logic, no window).
- **Manual/integration checklist** (documented in README; requires a real notch):
  window position over notch, hover-expand/collapse, spring feel, drop a file →
  appears in shelf → drag out to Finder, Calendar grant flow, Music/Spotify control.
- Tests run via `swift test`. Logic is deliberately separated from AppKit/SwiftUI so
  the bulk is testable headlessly.

## 11. Project layout

```
MacNotch/
├── Package.swift
├── Makefile
├── README.md
├── MacNotch.entitlements
├── Scripts/
│   ├── package-app.sh
│   └── run.sh
├── Sources/MacNotch/
│   ├── App/            AppCore, MenuBarController, SettingsStore, LoginItem
│   ├── Window/         NotchWindow, NotchStateMachine, ScreenLocator
│   ├── UI/             NotchRootView, ModuleStack, shared SwiftUI components
│   └── Modules/
│       ├── ModuleProtocol.swift   (NotchModule)
│       ├── Media/      MediaController, MediaSource, AppleScriptSource, MediaRemoteSource, views
│       ├── Calendar/   CalendarModule, views
│       ├── System/     SystemModule, sampling, views
│       └── Shelf/      ShelfModule, ShelfStore, views
├── Resources/          assets (icons)
└── Tests/MacNotchTests/
```

## 12. Open risks / things to validate early

1. **Notch geometry on macOS 26** — confirm `safeAreaInsets`/`auxiliaryTopLeftArea`
   give a usable notch frame; validate the borderless `NSPanel` sits flush under the
   menu bar at `.statusBar+1`. *De-risk first, before modules.*
2. **MediaRemote on 26.x** — assume dead; AppleScript is the real path. Confirm
   AppleScript control of Music + Spotify works under Automation TCC.
3. **TCC stickiness** with ad-hoc re-signing — confirm it's tolerable; document.
4. **Spring vs. NSPanel resize** — verify the "resize-to-max, animate-content"
   approach avoids visible window jank.

## 13. Phasing (beyond this spec)

Phase 2+ each get their own spec and plug in via `NotchModule`: weather, Pomodoro,
GitHub/GitLab, notifications, translation, Bluetooth, Drop **actions**
(AirDrop/zip/convert/iCloud), multi-display, app shortcuts. None affect Phase 1's
interfaces if the `NotchModule` seam holds.

---

## Success criteria for Phase 1

- App launches as a menu-bar agent; notch shell appears over the physical notch.
- Hover/click expands into the module stack with a smooth spring; exits collapse it.
- Now Playing controls Music/Spotify and shows live track info.
- Calendar shows today's events after granting access.
- Battery/System shows live battery + CPU/RAM.
- Dropping a file onto the panel parks it in the shelf; it persists across launches
  and can be dragged back out to Finder.
- Settings enables/disables and reorders modules; launch-at-login works.
- Builds and packages to a runnable `.app` via `make run`, no Xcode.
