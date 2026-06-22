# MacNotch Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a personal native macOS app that turns the MacBook notch into a modular dashboard — a borderless notch window that expands on hover into a stack of modules (Now Playing, Calendar, Battery/System, Drop Shelf).

**Architecture:** A menu-bar agent app (`LSUIElement`) owns a borderless `NSPanel` positioned over the physical notch. The panel hosts a SwiftUI tree via `NSHostingView`. Modules conform to a `NotchModule` protocol and are rendered by a `ModuleStack`; the window knows nothing about module internals. Pure logic (state machine, settings, media selection, shelf store, system formatting) is separated from AppKit/SwiftUI so it is unit-testable with `swift test`.

**Tech Stack:** Swift 6.3, SwiftPM (executable + test target, **no Xcode**), AppKit (`NSPanel`, `NSStatusItem`, drag-and-drop), SwiftUI (views), EventKit (calendar), IOKit + `host_statistics64` (system), ScriptingBridge/AppleScript (media), `SMAppService` (login item). Packaged into a `.app` and ad-hoc signed by a shell script.

## Global Constraints

- Platform floor: `.macOS(.v14)`; built and run on macOS 26.5, Apple Silicon (arm64).
- **No Xcode / no `xcodebuild`.** Build only with `swift build`. The `.app` bundle is assembled by `Scripts/package-app.sh`.
- **No XCTest/Testing in this environment** (they ship only with Xcode). Tests run via a self-contained runner executable: `swift run MacNotchTests`, which exits non-zero on any failure. See the Testing Convention below.
- Distribution is **personal/local only**: ad-hoc codesign (`codesign --sign -`), no notarization, no sandbox.
- Bundle id: `io.local.macnotch`. App is an agent: `Info.plist` sets `LSUIElement = true` (no Dock icon).
- Required `Info.plist` usage strings: `NSCalendarsUsageDescription`, `NSAppleEventsUsageDescription`.
- All external reads (AppleScript, EventKit, IOKit) must be failable and degrade to a quiet placeholder — a failing module must never crash the shell.
- TDD: write the failing test first, watch it fail, implement minimally, watch it pass, commit. Pure-logic tasks are fully tested with `swift run MacNotchTests`; AppKit/SwiftUI tasks (windowing, views, drag-and-drop) end with a documented **manual verification** step because they cannot run headlessly.
- Every commit message ends with the trailer:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`
- Commit after every task. Keep commits small.

**Testing Convention (replaces XCTest):** All logic under test lives in the
`MacNotchKit` library and is declared `public`, so tests use a plain
`import MacNotchKit` (no `@testable`). A test file defines a single free
function `func <area>Tests()` that registers cases with the harness helpers
`test(_:_:)`, `expect(_:_:)`, and `expectEqual(_:_:_:)` (defined in Task 1's
`Harness.swift`). The runner's `Sources/MacNotchTests/main.swift` calls each
`<area>Tests()` function and then `exit(Int32(TestRunner.shared.runAll()))`.
**Every task that adds a test file must append its `<area>Tests()` call to that
`main.swift`.** Translation from the XCTest snippets shown in later tasks is
mechanical: `XCTAssertEqual(a, b)` → `expectEqual(a, b, "label")`;
`XCTAssertTrue(x)`/`XCTAssertFalse(x)` → `expect(x, "label")`/`expect(!x, "label")`;
`XCTAssertNil(x)` → `expect(x == nil, "label")`; each `func testFoo()` becomes a
`test("foo") { ... }` block inside the area function.

**Module map (locked in during design):**

```
Sources/MacNotchKit/         (library target — all logic + AppKit/SwiftUI, public API)
├── AppCore.swift            version, bundle id
├── App/        MacNotchApp (entry point), AppDelegate, MenuBarController,
│               SettingsStore, AppSettings, LoginItem, SettingsView, SettingsWindowController
├── Window/     NotchWindow, NotchStateMachine, ScreenLocator, ScreenInfo
├── UI/         NotchRootView, ModuleStack (ModuleRegistry)
└── Modules/
    ├── ModuleProtocol.swift          NotchModule
    ├── Media/    MediaModule, MediaController, MediaSource, NowPlaying,
    │             AppleScriptSource, MediaRemoteSource, MediaViews
    ├── Calendar/ CalendarModule, CalendarViews
    ├── System/   SystemModule, SystemSampler, SystemSample, SystemViews
    └── Shelf/    ShelfModule, ShelfStore, ShelfItem, ShelfViews
Sources/MacNotch/main.swift        (thin executable: import MacNotchKit; MacNotchApp.run())
Sources/MacNotchTests/             (executable test runner)
├── Harness.swift                  TestRunner + test/expect/expectEqual
├── main.swift                     calls each <area>Tests(), exits non-zero on failure
└── <Area>Tests.swift              one file per pure-logic unit
```

> **Path note:** the plan's later tasks were written before this restructure and
> say `Sources/MacNotch/App/...`, `Sources/MacNotch/Window/...`, etc., and
> `Tests/MacNotchTests/...`. Those now live under **`Sources/MacNotchKit/...`**
> (production code) and **`Sources/MacNotchTests/...`** (tests) respectively.
> Keep the same subfolders and filenames; only the top-level target dir changes.

---

### Task 1: Project scaffold + self-contained test harness

This project's toolchain (Command Line Tools, no Xcode) has **no XCTest and no
Testing module**, so we use three targets: a `MacNotchKit` library holding all
code, a thin `MacNotch` executable, and a `MacNotchTests` executable that runs a
hand-rolled assertion harness. Tests run with `swift run MacNotchTests`.

**Files:**
- Create: `Package.swift`
- Create: `Sources/MacNotchKit/AppCore.swift`
- Create: `Sources/MacNotch/main.swift`
- Create: `Sources/MacNotchTests/Harness.swift`
- Create: `Sources/MacNotchTests/SanityTests.swift`
- Create: `Sources/MacNotchTests/main.swift`
- Create: `Makefile`

**Interfaces:**
- Produces: library target `MacNotchKit` (public API, `-enable-testing` not needed
  because everything tested is `public`); executable `MacNotch`; executable
  `MacNotchTests`; `AppCore.version: String`, `AppCore.bundleID: String`; harness
  helpers `test(_:_:)`, `expect(_:_:)`, `expectEqual(_:_:_:)`, and
  `TestRunner.shared.runAll() -> Int`.

- [ ] **Step 1: Write `Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacNotch",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "MacNotchKit",
            path: "Sources/MacNotchKit"
        ),
        .executableTarget(
            name: "MacNotch",
            dependencies: ["MacNotchKit"],
            path: "Sources/MacNotch"
        ),
        .executableTarget(
            name: "MacNotchTests",
            dependencies: ["MacNotchKit"],
            path: "Sources/MacNotchTests"
        ),
    ]
)
```

- [ ] **Step 2: Write `AppCore` (in the library) and the thin executable**

`Sources/MacNotchKit/AppCore.swift`:

```swift
import Foundation

public enum AppCore {
    public static let version = "0.1.0"
    public static let bundleID = "io.local.macnotch"
}
```

`Sources/MacNotch/main.swift`:

```swift
import MacNotchKit

// Real agent bootstrap is added in Task 6 (MacNotchApp.run()). For now, prove the
// executable links against the library and runs.
print("MacNotch \(AppCore.version)")
```

- [ ] **Step 3: Write the test harness**

`Sources/MacNotchTests/Harness.swift`:

```swift
import Foundation

public final class TestRunner {
    public static let shared = TestRunner()
    private var cases: [(String, () -> Void)] = []
    private(set) var checks = 0
    private(set) var failures = 0

    public func add(_ name: String, _ body: @escaping () -> Void) {
        cases.append((name, body))
    }

    public func record(_ pass: Bool, _ msg: String, _ file: String, _ line: Int) {
        checks += 1
        if pass {
            print("  ✓ \(msg)")
        } else {
            failures += 1
            print("  ✗ FAIL: \(msg)  [\(file):\(line)]")
        }
    }

    /// Runs every registered case; returns a process exit code (0 = all passed).
    public func runAll() -> Int {
        for (name, body) in cases {
            print("• \(name)")
            body()
        }
        print("\n\(checks) checks, \(failures) failure(s)")
        return failures == 0 ? 0 : 1
    }
}

public func test(_ name: String, _ body: @escaping () -> Void) {
    TestRunner.shared.add(name, body)
}

public func expect(_ condition: @autoclosure () -> Bool, _ message: String,
                   file: String = #fileID, line: Int = #line) {
    TestRunner.shared.record(condition(), message, file, line)
}

public func expectEqual<T: Equatable>(_ a: @autoclosure () -> T,
                                      _ b: @autoclosure () -> T,
                                      _ message: String,
                                      file: String = #fileID, line: Int = #line) {
    let av = a(), bv = b()
    TestRunner.shared.record(av == bv, "\(message) (\(av) == \(bv))", file, line)
}
```

- [ ] **Step 4: Write the failing sanity test**

`Sources/MacNotchTests/SanityTests.swift`:

```swift
import MacNotchKit

func sanityTests() {
    test("AppCore version and bundle id") {
        expectEqual(AppCore.version, "0.1.0", "version")
        expectEqual(AppCore.bundleID, "io.local.macnotch", "bundleID")
    }
}
```

`Sources/MacNotchTests/main.swift`:

```swift
import Foundation

// Register each area's tests, then run. Later tasks append their <area>Tests() call here.
sanityTests()

exit(Int32(TestRunner.shared.runAll()))
```

- [ ] **Step 5: Run the tests**

Run: `swift run MacNotchTests`
Expected: builds and prints `✓ version`, `✓ bundleID`, then `2 checks, 0 failure(s)`; process exits 0. (To see RED first, temporarily change the expected version string, run, observe a `✗ FAIL`, then revert.)

- [ ] **Step 6: Write the `Makefile`**

```makefile
.PHONY: build test run package clean
build:
	swift build
test:
	swift run MacNotchTests
package:
	bash Scripts/package-app.sh
run: package
	open ./build/MacNotch.app
clean:
	swift package clean
	rm -rf build
```

- [ ] **Step 7: Verify build + commit**

Run: `swift build && swift run MacNotchTests`
Expected: build succeeds, `2 checks, 0 failure(s)`.

```bash
git add Package.swift Sources Makefile
git commit -m "Scaffold SwiftPM project with self-contained test harness"
```

---

### Task 2: Packaging script → runnable `.app`

**Files:**
- Create: `Scripts/package-app.sh`
- Create: `MacNotch.entitlements`

**Interfaces:**
- Produces: `build/MacNotch.app`, ad-hoc signed, launchable. No code interface.

- [ ] **Step 1: Write `MacNotch.entitlements`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 2: Write `Scripts/package-app.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/MacNotch.app"
BIN_SRC="$ROOT/.build/release/MacNotch"

echo "==> swift build -c release"
swift build -c release --package-path "$ROOT"

echo "==> assembling bundle"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_SRC" "$APP/Contents/MacOS/MacNotch"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>MacNotch</string>
  <key>CFBundleDisplayName</key><string>MacNotch</string>
  <key>CFBundleIdentifier</key><string>io.local.macnotch</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleExecutable</key><string>MacNotch</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSCalendarsUsageDescription</key>
  <string>MacNotch shows your upcoming events in the notch.</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>MacNotch controls Music and Spotify playback from the notch.</string>
</dict>
</plist>
PLIST

echo "==> ad-hoc codesign"
codesign --force --deep --sign - \
  --entitlements "$ROOT/MacNotch.entitlements" "$APP"

echo "==> built $APP"
```

- [ ] **Step 3: Make it executable and package**

Run:
```bash
chmod +x Scripts/package-app.sh
make package
```
Expected: prints `built .../build/MacNotch.app`, no errors.

- [ ] **Step 4: Manual verification — launch**

Run: `open ./build/MacNotch.app`
Expected: the app launches as an agent (no Dock icon, no window yet — `main.swift` only prints and exits, so the process ends immediately; this confirms the bundle is valid and signed). Confirm with `codesign -dv ./build/MacNotch.app 2>&1 | head` showing `Signature=adhoc`.

- [ ] **Step 5: Commit**

```bash
git add Scripts/package-app.sh MacNotch.entitlements
git commit -m "Add .app packaging script with ad-hoc signing"
```

---

### Task 3: `NotchStateMachine` (pure logic, TDD)

**Files:**
- Create: `Sources/MacNotchKit/Window/NotchStateMachine.swift`
- Create: `Sources/MacNotchTests/NotchStateMachineTests.swift`
- Modify: `Sources/MacNotchTests/main.swift` (register the new tests)

**Interfaces:**
- Produces:
  - `enum NotchState { case collapsed, expanded }` (no associated values → implicitly `Equatable`, so `expectEqual` works on it)
  - `final class NotchStateMachine` with `var state: NotchState` (default `.collapsed`), `var hoverToExpand: Bool` (default `true`), and mutating methods returning `Bool` (whether state changed): `hoverChanged(_ inside: Bool) -> Bool`, `clicked() -> Bool`, `mouseExitedPanel() -> Bool`, `clickedOutside() -> Bool`.

- [ ] **Step 1: Write the failing tests (harness style)**

`Sources/MacNotchTests/NotchStateMachineTests.swift`:

```swift
import MacNotchKit

func notchStateMachineTests() {
    test("hover enter expands when enabled") {
        let sm = NotchStateMachine()
        expect(sm.hoverChanged(true), "hover returns changed")
        expectEqual(sm.state, .expanded, "state")
    }
    test("hover enter does nothing when disabled") {
        let sm = NotchStateMachine()
        sm.hoverToExpand = false
        expect(!sm.hoverChanged(true), "hover returns no change")
        expectEqual(sm.state, .collapsed, "state")
    }
    test("click toggles both ways") {
        let sm = NotchStateMachine()
        expect(sm.clicked(), "first click changed"); expectEqual(sm.state, .expanded, "expanded")
        expect(sm.clicked(), "second click changed"); expectEqual(sm.state, .collapsed, "collapsed")
    }
    test("mouse exit collapses") {
        let sm = NotchStateMachine()
        _ = sm.clicked()
        expect(sm.mouseExitedPanel(), "exit changed")
        expectEqual(sm.state, .collapsed, "state")
    }
    test("clicked outside collapses only when expanded") {
        let sm = NotchStateMachine()
        expect(!sm.clickedOutside(), "no change when collapsed")
        _ = sm.clicked()
        expect(sm.clickedOutside(), "collapses when expanded")
        expectEqual(sm.state, .collapsed, "state")
    }
}
```

Then register it in `Sources/MacNotchTests/main.swift` — add the call below `sanityTests()` (keep the `exit(...)` line last):

```swift
sanityTests()
notchStateMachineTests()

exit(Int32(TestRunner.shared.runAll()))
```

- [ ] **Step 2: Run to verify failure**

Run: `swift run MacNotchTests`
Expected: build FAILS to compile — `cannot find 'NotchStateMachine' in scope` (the type doesn't exist yet). This is the RED state.

- [ ] **Step 3: Implement**

`Sources/MacNotchKit/Window/NotchStateMachine.swift`:

```swift
import Foundation

public enum NotchState { case collapsed, expanded }

public final class NotchStateMachine {
    public private(set) var state: NotchState = .collapsed
    public var hoverToExpand = true

    public init() {}

    /// Returns true if `state` changed.
    public func hoverChanged(_ inside: Bool) -> Bool {
        if inside {
            guard hoverToExpand, state == .collapsed else { return false }
            state = .expanded; return true
        } else {
            return mouseExitedPanel()
        }
    }

    public func clicked() -> Bool {
        state = (state == .collapsed) ? .expanded : .collapsed
        return true
    }

    public func mouseExitedPanel() -> Bool {
        guard state == .expanded else { return false }
        state = .collapsed; return true
    }

    public func clickedOutside() -> Bool { mouseExitedPanel() }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `swift run MacNotchTests`
Expected: the 5 `NotchStateMachine` cases print `✓`, and the final line's failure count is 0.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacNotchKit/Window/NotchStateMachine.swift Sources/MacNotchTests/NotchStateMachineTests.swift Sources/MacNotchTests/main.swift
git commit -m "Add NotchStateMachine with collapse/expand transitions"
```

---

### Task 4: `AppSettings` + `SettingsStore` (pure logic, TDD)

**Files:**
- Create: `Sources/MacNotchKit/App/AppSettings.swift`
- Create: `Sources/MacNotchKit/App/SettingsStore.swift`
- Create: `Sources/MacNotchTests/SettingsStoreTests.swift`
- Modify: `Sources/MacNotchTests/main.swift` (register the new tests)

**Interfaces:**
- Produces:
  - `struct ModuleSetting: Codable, Equatable { var id: String; var isEnabled: Bool }`
  - `struct AppSettings: Codable, Equatable { var modules: [ModuleSetting]; var launchAtLogin: Bool; static var defaults: AppSettings }`
  - `final class SettingsStore` init with a file `URL`; `var settings: AppSettings`; `func load()`; `func save()`; `func setEnabled(_ id: String, _ on: Bool)`; `func move(id: String, to index: Int)`; `func orderedEnabledIDs() -> [String]`.

- [ ] **Step 1: Write failing tests (harness style)**

`Sources/MacNotchTests/SettingsStoreTests.swift`:

```swift
import Foundation
import MacNotchKit

func settingsStoreTests() {
    func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
    }

    test("round-trips settings to disk") {
        let url = tempURL()
        let a = SettingsStore(url: url)
        a.setEnabled("media", false)
        a.save()

        let b = SettingsStore(url: url)
        b.load()
        let media = b.settings.modules.first { $0.id == "media" }
        expect(media?.isEnabled == false, "media disabled after reload")
    }

    test("reorder moves module to the end") {
        let store = SettingsStore(url: tempURL())
        let first = store.settings.modules.first!.id
        store.move(id: first, to: store.settings.modules.count - 1)
        expectEqual(store.settings.modules.last!.id, first, "moved id is last")
    }

    test("orderedEnabledIDs skips disabled") {
        let store = SettingsStore(url: tempURL())
        store.setEnabled("system", false)
        expect(!store.orderedEnabledIDs().contains("system"), "system excluded")
        expect(store.orderedEnabledIDs().contains("media"), "media included")
    }
}
```

Then register it in `Sources/MacNotchTests/main.swift` (add below the previous registrations, keep `exit(...)` last):

```swift
settingsStoreTests()
```

- [ ] **Step 2: Run to verify failure**

Run: `swift run MacNotchTests`
Expected: build FAILS to compile — `cannot find 'SettingsStore' in scope` (types don't exist yet). This is RED.

- [ ] **Step 3: Implement `AppSettings`**

`Sources/MacNotchKit/App/AppSettings.swift`:

```swift
import Foundation

public struct ModuleSetting: Codable, Equatable {
    public var id: String
    public var isEnabled: Bool
}

public struct AppSettings: Codable, Equatable {
    public var modules: [ModuleSetting]
    public var launchAtLogin: Bool

    public static let defaults = AppSettings(
        modules: [
            ModuleSetting(id: "media", isEnabled: true),
            ModuleSetting(id: "calendar", isEnabled: true),
            ModuleSetting(id: "system", isEnabled: true),
            ModuleSetting(id: "shelf", isEnabled: true),
        ],
        launchAtLogin: false
    )
}
```

- [ ] **Step 4: Implement `SettingsStore`**

`Sources/MacNotchKit/App/SettingsStore.swift`:

```swift
import Foundation

public final class SettingsStore {
    public private(set) var settings: AppSettings
    private let url: URL

    public init(url: URL) {
        self.url = url
        self.settings = .defaults
    }

    public func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return }
        settings = decoded
    }

    public func save() {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(settings) {
            try? data.write(to: url, options: .atomic)
        }
    }

    public func setEnabled(_ id: String, _ on: Bool) {
        guard let i = settings.modules.firstIndex(where: { $0.id == id }) else { return }
        settings.modules[i].isEnabled = on
    }

    public func move(id: String, to index: Int) {
        guard let from = settings.modules.firstIndex(where: { $0.id == id }) else { return }
        let item = settings.modules.remove(at: from)
        let clamped = max(0, min(index, settings.modules.count))
        settings.modules.insert(item, at: clamped)
    }

    public func orderedEnabledIDs() -> [String] {
        settings.modules.filter { $0.isEnabled }.map { $0.id }
    }

    /// Default store location in Application Support.
    public static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        return base.appendingPathComponent("MacNotch/settings.json")
    }
}
```

- [ ] **Step 5: Run to verify pass + commit**

Run: `swift run MacNotchTests`
Expected: the 3 `SettingsStore` cases print `✓`, final failure count 0.

```bash
git add Sources/MacNotchKit/App/AppSettings.swift Sources/MacNotchKit/App/SettingsStore.swift Sources/MacNotchTests/SettingsStoreTests.swift Sources/MacNotchTests/main.swift
git commit -m "Add AppSettings model and SettingsStore with reorder/persist"
```

---

### Task 5: `NotchModule` protocol + `ModuleStack` ordering (TDD with fakes)

**Files:**
- Create: `Sources/MacNotch/Modules/ModuleProtocol.swift`
- Create: `Sources/MacNotch/UI/ModuleStack.swift`
- Test: `Tests/MacNotchTests/ModuleStackTests.swift`

**Interfaces:**
- Produces:
  - `@MainActor protocol NotchModule: AnyObject { var id: String { get }; var title: String { get }; var isEnabled: Bool { get set }; func collapsedView() -> AnyView?; func expandedView() -> AnyView; func activate(); func deactivate(); func refresh() async }`
  - `@MainActor final class ModuleRegistry` with `register(_:)` and `func ordered(by ids: [String]) -> [any NotchModule]`.
- Consumes: `SettingsStore.orderedEnabledIDs()` (Task 4).

- [ ] **Step 1: Write failing test**

`Tests/MacNotchTests/ModuleStackTests.swift`:

```swift
import XCTest
import SwiftUI
@testable import MacNotch

@MainActor
final class ModuleStackTests: XCTestCase {
    final class FakeModule: NotchModule {
        let id: String; var title: String; var isEnabled = true
        init(_ id: String) { self.id = id; self.title = id }
        func collapsedView() -> AnyView? { nil }
        func expandedView() -> AnyView { AnyView(EmptyView()) }
        func activate() {}; func deactivate() {}; func refresh() async {}
    }

    func testOrderedFollowsRequestedIDs() {
        let reg = ModuleRegistry()
        reg.register(FakeModule("a"))
        reg.register(FakeModule("b"))
        reg.register(FakeModule("c"))
        let ordered = reg.ordered(by: ["c", "a"])
        XCTAssertEqual(ordered.map(\.id), ["c", "a"])
    }

    func testUnknownIDsAreIgnored() {
        let reg = ModuleRegistry()
        reg.register(FakeModule("a"))
        XCTAssertEqual(reg.ordered(by: ["zzz", "a"]).map(\.id), ["a"])
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --filter ModuleStackTests`
Expected: FAIL — `NotchModule`/`ModuleRegistry` undefined.

- [ ] **Step 3: Implement the protocol**

`Sources/MacNotch/Modules/ModuleProtocol.swift`:

```swift
import SwiftUI

@MainActor
public protocol NotchModule: AnyObject {
    var id: String { get }
    var title: String { get }
    var isEnabled: Bool { get set }

    func collapsedView() -> AnyView?
    func expandedView() -> AnyView
    func activate()
    func deactivate()
    func refresh() async
}
```

- [ ] **Step 4: Implement `ModuleRegistry`**

`Sources/MacNotch/UI/ModuleStack.swift`:

```swift
import SwiftUI

@MainActor
public final class ModuleRegistry {
    private var modules: [String: any NotchModule] = [:]
    private var registrationOrder: [String] = []

    public init() {}

    public func register(_ module: any NotchModule) {
        if modules[module.id] == nil { registrationOrder.append(module.id) }
        modules[module.id] = module
    }

    /// Returns modules in the requested id order, skipping unknown ids.
    public func ordered(by ids: [String]) -> [any NotchModule] {
        ids.compactMap { modules[$0] }
    }

    public var all: [any NotchModule] { registrationOrder.compactMap { modules[$0] } }
}
```

- [ ] **Step 5: Run to verify pass + commit**

Run: `swift test --filter ModuleStackTests`
Expected: PASS (2 tests).

```bash
git add Sources/MacNotch/Modules/ModuleProtocol.swift Sources/MacNotch/UI/ModuleStack.swift Tests/MacNotchTests/ModuleStackTests.swift
git commit -m "Add NotchModule protocol and ModuleRegistry ordering"
```

---

### Task 6: Agent bootstrap + menu-bar item (AppKit, manual verify)

**Files:**
- Modify: `Sources/MacNotch/main.swift`
- Create: `Sources/MacNotch/App/MenuBarController.swift`
- Create: `Sources/MacNotch/App/AppDelegate.swift`

**Interfaces:**
- Produces: `final class AppDelegate: NSObject, NSApplicationDelegate` (owns `MenuBarController`), `final class MenuBarController` (creates an `NSStatusItem` with menu: "Open Settings…", "Toggle Notch", "Quit MacNotch"). `MenuBarController` exposes `var onOpenSettings: (() -> Void)?` and `var onToggleNotch: (() -> Void)?` callbacks (wired in later tasks).

- [ ] **Step 1: Implement `MenuBarController`**

`Sources/MacNotch/App/MenuBarController.swift`:

```swift
import AppKit

@MainActor
final class MenuBarController {
    private let item: NSStatusItem
    var onOpenSettings: (() -> Void)?
    var onToggleNotch: (() -> Void)?

    init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled",
                                     accessibilityDescription: "MacNotch")
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Settings…", action: #selector(openSettings), keyEquivalent: ",")
            .target = self
        menu.addItem(withTitle: "Toggle Notch", action: #selector(toggleNotch), keyEquivalent: "")
            .target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit MacNotch", action: #selector(quit), keyEquivalent: "q")
            .target = self
        item.menu = menu
    }

    @objc private func openSettings() { onOpenSettings?() }
    @objc private func toggleNotch() { onToggleNotch?() }
    @objc private func quit() { NSApp.terminate(nil) }
}
```

- [ ] **Step 2: Implement `AppDelegate`**

`Sources/MacNotch/App/AppDelegate.swift`:

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController()
        // NotchWindow is wired in Task 8.
    }
}
```

- [ ] **Step 3: Rewrite `main.swift` as the agent entry point**

`Sources/MacNotch/main.swift`:

```swift
import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // agent: no Dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 4: Build + manual verification**

Run: `make run`
Expected: a menu-bar icon (a notch glyph) appears in the system status bar. Clicking it shows "Open Settings…", "Toggle Notch", "Quit MacNotch". "Quit" terminates the app. (Settings/Toggle are no-ops until later tasks.)

- [ ] **Step 5: Commit**

```bash
git add Sources/MacNotch/App/MenuBarController.swift Sources/MacNotch/App/AppDelegate.swift Sources/MacNotch/main.swift
git commit -m "Add agent bootstrap and menu-bar controller"
```

---

### Task 7: `ScreenLocator` + `ScreenInfo` (notch geometry, TDD logic + manual)

**Files:**
- Create: `Sources/MacNotch/Window/ScreenInfo.swift`
- Create: `Sources/MacNotch/Window/ScreenLocator.swift`
- Test: `Tests/MacNotchTests/ScreenLocatorTests.swift`

**Interfaces:**
- Produces:
  - `struct ScreenInfo: Equatable { var frame: CGRect; var safeAreaTop: CGFloat; var notchWidth: CGFloat?; var isMain: Bool }`
  - `enum ScreenLocator { static func choose(from screens: [ScreenInfo]) -> ScreenInfo?; static func notchRect(for screen: ScreenInfo, defaultWidth: CGFloat) -> CGRect }`
  - Plus a `static func current() -> [ScreenInfo]` that maps real `NSScreen`s (used by the window, not by tests).

- [ ] **Step 1: Write failing tests**

`Tests/MacNotchTests/ScreenLocatorTests.swift`:

```swift
import XCTest
@testable import MacNotch

final class ScreenLocatorTests: XCTestCase {
    private func screen(top: CGFloat, notch: CGFloat?, main: Bool) -> ScreenInfo {
        ScreenInfo(frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
                   safeAreaTop: top, notchWidth: notch, isMain: main)
    }

    func testPrefersScreenWithNotch() {
        let external = screen(top: 0, notch: nil, main: true)
        let laptop = screen(top: 38, notch: 200, main: false)
        XCTAssertEqual(ScreenLocator.choose(from: [external, laptop]), laptop)
    }

    func testFallsBackToMainWhenNoNotch() {
        let external = screen(top: 0, notch: nil, main: true)
        let other = screen(top: 0, notch: nil, main: false)
        XCTAssertEqual(ScreenLocator.choose(from: [other, external]), external)
    }

    func testNotchRectIsTopCenteredWithGivenWidth() {
        let s = screen(top: 38, notch: 200, main: true)
        let rect = ScreenLocator.notchRect(for: s, defaultWidth: 220)
        XCTAssertEqual(rect.width, 200)            // real notch width wins
        XCTAssertEqual(rect.midX, s.frame.midX)    // centered
        XCTAssertEqual(rect.maxY, s.frame.maxY)    // hugs the top
    }

    func testNotchRectUsesDefaultWidthWhenNoNotch() {
        let s = screen(top: 0, notch: nil, main: true)
        let rect = ScreenLocator.notchRect(for: s, defaultWidth: 220)
        XCTAssertEqual(rect.width, 220)
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --filter ScreenLocatorTests`
Expected: FAIL — undefined types.

- [ ] **Step 3: Implement `ScreenInfo`**

`Sources/MacNotch/Window/ScreenInfo.swift`:

```swift
import CoreGraphics

public struct ScreenInfo: Equatable {
    public var frame: CGRect
    public var safeAreaTop: CGFloat
    public var notchWidth: CGFloat?
    public var isMain: Bool

    public init(frame: CGRect, safeAreaTop: CGFloat, notchWidth: CGFloat?, isMain: Bool) {
        self.frame = frame; self.safeAreaTop = safeAreaTop
        self.notchWidth = notchWidth; self.isMain = isMain
    }

    public var hasNotch: Bool { safeAreaTop > 0 }
}
```

- [ ] **Step 4: Implement `ScreenLocator`**

`Sources/MacNotch/Window/ScreenLocator.swift`:

```swift
import AppKit

public enum ScreenLocator {
    /// Prefer a screen with a physical notch; else the main screen; else the first.
    public static func choose(from screens: [ScreenInfo]) -> ScreenInfo? {
        if let notched = screens.first(where: { $0.hasNotch }) { return notched }
        if let main = screens.first(where: { $0.isMain }) { return main }
        return screens.first
    }

    /// A top-centered rect; uses the real notch width when known, else `defaultWidth`.
    public static func notchRect(for screen: ScreenInfo, defaultWidth: CGFloat) -> CGRect {
        let width = screen.notchWidth ?? defaultWidth
        let height = max(screen.safeAreaTop, 32)
        let x = screen.frame.midX - width / 2
        let y = screen.frame.maxY - height
        return CGRect(x: x, y: y, width: width, height: height)
    }

    /// Maps live NSScreens to ScreenInfo. Not exercised by unit tests.
    public static func current() -> [ScreenInfo] {
        NSScreen.screens.map { s in
            let aux = s.auxiliaryTopLeftArea
            let notchW: CGFloat? = s.safeAreaInsets.top > 0
                ? (s.frame.width - 2 * (aux?.width ?? 0)).rounded()
                : nil
            return ScreenInfo(frame: s.frame,
                              safeAreaTop: s.safeAreaInsets.top,
                              notchWidth: (notchW.map { $0 > 0 ? $0 : nil } ?? nil),
                              isMain: s == NSScreen.main)
        }
    }
}
```

- [ ] **Step 5: Run to verify pass**

Run: `swift test --filter ScreenLocatorTests`
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
git add Sources/MacNotch/Window/ScreenInfo.swift Sources/MacNotch/Window/ScreenLocator.swift Tests/MacNotchTests/ScreenLocatorTests.swift
git commit -m "Add ScreenLocator and ScreenInfo with notch geometry"
```

---

### Task 8: `NotchWindow` + placeholder panel (AppKit/SwiftUI, manual verify)

**Files:**
- Create: `Sources/MacNotch/UI/NotchRootView.swift`
- Create: `Sources/MacNotch/Window/NotchWindow.swift`
- Modify: `Sources/MacNotch/App/AppDelegate.swift`

**Interfaces:**
- Consumes: `NotchStateMachine` (Task 3), `ScreenLocator`/`ScreenInfo` (Task 7), `ModuleRegistry` (Task 5).
- Produces:
  - `@MainActor final class NotchWindowModel: ObservableObject { @Published var isExpanded: Bool }`
  - `@MainActor final class NotchWindow` with `init(registry: ModuleRegistry, settings: SettingsStore)`, `func show()`, `func toggle()`. Internally owns the `NSPanel`, the `NotchStateMachine`, and a `NotchWindowModel`.
  - `struct NotchRootView: View` taking `@ObservedObject model` + the ordered modules; shows the collapsed glance vs. the expanded module stack with a spring animation.

- [ ] **Step 1: Implement `NotchRootView` (placeholder modules)**

`Sources/MacNotch/UI/NotchRootView.swift`:

```swift
import SwiftUI

@MainActor
public final class NotchWindowModel: ObservableObject {
    @Published public var isExpanded = false
    public init() {}
}

public struct NotchRootView: View {
    @ObservedObject var model: NotchWindowModel
    let expandedWidth: CGFloat
    let collapsedSize: CGSize
    let modules: () -> [any NotchModule]

    public init(model: NotchWindowModel,
                expandedWidth: CGFloat,
                collapsedSize: CGSize,
                modules: @escaping () -> [any NotchModule]) {
        self.model = model
        self.expandedWidth = expandedWidth
        self.collapsedSize = collapsedSize
        self.modules = modules
    }

    public var body: some View {
        VStack(spacing: 0) {
            if model.isExpanded {
                VStack(spacing: 10) {
                    ForEach(Array(modules().enumerated()), id: \.offset) { _, module in
                        module.expandedView()
                    }
                }
                .padding(14)
                .frame(width: expandedWidth)
                .transition(.opacity)
            } else {
                HStack(spacing: 6) {
                    ForEach(Array(modules().enumerated()), id: \.offset) { _, module in
                        if let c = module.collapsedView() { c }
                    }
                }
                .frame(minWidth: collapsedSize.width, minHeight: collapsedSize.height)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: model.isExpanded ? 20 : 12, style: .continuous)
                .fill(.black)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: model.isExpanded)
    }
}
```

- [ ] **Step 2: Implement `NotchWindow`**

`Sources/MacNotch/Window/NotchWindow.swift`:

```swift
import AppKit
import SwiftUI

@MainActor
public final class NotchWindow {
    private let panel: NSPanel
    private let model = NotchWindowModel()
    private let machine = NotchStateMachine()
    private let registry: ModuleRegistry
    private let settings: SettingsStore
    private let expandedWidth: CGFloat = 280
    private let expandedHeight: CGFloat = 320

    public init(registry: ModuleRegistry, settings: SettingsStore) {
        self.registry = registry
        self.settings = settings

        panel = NSPanel(contentRect: .zero,
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = false

        let root = NotchRootView(
            model: model,
            expandedWidth: expandedWidth,
            collapsedSize: CGSize(width: notchRect.width, height: notchRect.height),
            modules: { [weak self] in self?.orderedModules() ?? [] }
        )
        panel.contentView = NSHostingView(rootView: root)
        position()
        installHoverTracking()
    }

    private var notchRect: CGRect {
        let screens = ScreenLocator.current()
        let screen = ScreenLocator.choose(from: screens)
            ?? ScreenInfo(frame: NSScreen.main?.frame ?? .zero,
                          safeAreaTop: 0, notchWidth: nil, isMain: true)
        return ScreenLocator.notchRect(for: screen, defaultWidth: 200)
    }

    private func orderedModules() -> [any NotchModule] {
        registry.ordered(by: settings.orderedEnabledIDs())
    }

    private func position() {
        // Reserve the expanded footprint up front; SwiftUI animates content within it.
        let r = notchRect
        let frame = CGRect(x: r.midX - expandedWidth / 2,
                           y: r.maxY - expandedHeight,
                           width: expandedWidth, height: expandedHeight)
        panel.setFrame(frame, display: true)
    }

    private func installHoverTracking() {
        guard let view = panel.contentView else { return }
        let area = NSTrackingArea(
            rect: view.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self, userInfo: nil)
        view.addTrackingArea(area)
    }

    @objc public func mouseEntered(with event: NSEvent) { applyHover(true) }
    @objc public func mouseExited(with event: NSEvent) { applyHover(false) }

    private func applyHover(_ inside: Bool) {
        if machine.hoverChanged(inside) { sync() }
    }

    public func toggle() { if machine.clicked() { sync() } }

    private func sync() { model.isExpanded = (machine.state == .expanded) }

    public func show() {
        for m in orderedModules() { m.activate() }
        panel.orderFrontRegardless()
    }
}
```

> Note: `NSTrackingArea` owner methods (`mouseEntered`/`mouseExited`) must be reachable from AppKit; `NotchWindow` is the owner here. Because the hosting view covers the full expanded footprint, hover-expand will trigger anywhere in that footprint — acceptable for P1. A tighter collapsed hot-zone is a Phase 2 refinement.

- [ ] **Step 3: Wire `NotchWindow` into `AppDelegate`**

`Sources/MacNotch/App/AppDelegate.swift`:

```swift
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?
    private var notch: NotchWindow?
    private let registry = ModuleRegistry()
    private let settings = SettingsStore(url: SettingsStore.defaultURL())

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings.load()
        registerModules()

        let notch = NotchWindow(registry: registry, settings: settings)
        self.notch = notch
        notch.show()

        let menuBar = MenuBarController()
        menuBar.onToggleNotch = { [weak notch] in notch?.toggle() }
        menuBar.onOpenSettings = { /* wired in Task 13 */ }
        self.menuBar = menuBar
    }

    private func registerModules() {
        // Modules are registered in their own tasks (9–12). Empty for now.
    }
}
```

- [ ] **Step 4: Build + manual verification**

Run: `make run`
Expected: a small black rounded shape sits under the physical notch. Hovering it expands the black panel with a spring (empty for now — no modules registered yet); moving the mouse away collapses it. "Toggle Notch" in the menu also expands/collapses. On a Mac without a notch, the shape appears top-center of the main screen.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacNotch/UI/NotchRootView.swift Sources/MacNotch/Window/NotchWindow.swift Sources/MacNotch/App/AppDelegate.swift
git commit -m "Add NotchWindow panel with hover/click spring expansion"
```

---

### Task 9: System module (zero-dep canary — first real module)

**Files:**
- Create: `Sources/MacNotch/Modules/System/SystemSample.swift`
- Create: `Sources/MacNotch/Modules/System/SystemSampler.swift`
- Create: `Sources/MacNotch/Modules/System/SystemViews.swift`
- Create: `Sources/MacNotch/Modules/System/SystemModule.swift`
- Modify: `Sources/MacNotch/App/AppDelegate.swift:registerModules`
- Test: `Tests/MacNotchTests/SystemSampleTests.swift`

**Interfaces:**
- Produces:
  - `struct SystemSample { var batteryPercent: Int?; var isCharging: Bool; var cpuPercent: Double; var ramUsedBytes: UInt64 }`
  - `extension SystemSample { var batteryLabel: String; var ramLabel: String; var cpuLabel: String }` (pure formatting — tested)
  - `enum SystemSampler { static func sample() -> SystemSample }` (live IOKit/host — not unit-tested)
  - `final class SystemModule: NotchModule`

- [ ] **Step 1: Write failing tests (pure formatting)**

`Tests/MacNotchTests/SystemSampleTests.swift`:

```swift
import XCTest
@testable import MacNotch

final class SystemSampleTests: XCTestCase {
    func testBatteryLabelWithCharge() {
        let s = SystemSample(batteryPercent: 84, isCharging: true, cpuPercent: 12, ramUsedBytes: 0)
        XCTAssertEqual(s.batteryLabel, "84% ⚡")
    }
    func testBatteryLabelNoBattery() {
        let s = SystemSample(batteryPercent: nil, isCharging: false, cpuPercent: 0, ramUsedBytes: 0)
        XCTAssertEqual(s.batteryLabel, "—")
    }
    func testRamLabelFormatsGigabytes() {
        let s = SystemSample(batteryPercent: nil, isCharging: false, cpuPercent: 0,
                             ramUsedBytes: 9_300_000_000)
        XCTAssertEqual(s.ramLabel, "9.3 GB")
    }
    func testCpuLabelRoundsToInteger() {
        let s = SystemSample(batteryPercent: nil, isCharging: false, cpuPercent: 12.6, ramUsedBytes: 0)
        XCTAssertEqual(s.cpuLabel, "13%")
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --filter SystemSampleTests`
Expected: FAIL — `SystemSample` undefined.

- [ ] **Step 3: Implement `SystemSample` + formatting**

`Sources/MacNotch/Modules/System/SystemSample.swift`:

```swift
import Foundation

public struct SystemSample {
    public var batteryPercent: Int?
    public var isCharging: Bool
    public var cpuPercent: Double
    public var ramUsedBytes: UInt64

    public init(batteryPercent: Int?, isCharging: Bool, cpuPercent: Double, ramUsedBytes: UInt64) {
        self.batteryPercent = batteryPercent; self.isCharging = isCharging
        self.cpuPercent = cpuPercent; self.ramUsedBytes = ramUsedBytes
    }

    public var batteryLabel: String {
        guard let p = batteryPercent else { return "—" }
        return isCharging ? "\(p)% ⚡" : "\(p)%"
    }
    public var cpuLabel: String { "\(Int(cpuPercent.rounded()))%" }
    public var ramLabel: String {
        let gb = Double(ramUsedBytes) / 1_000_000_000
        return String(format: "%.1f GB", gb)
    }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `swift test --filter SystemSampleTests`
Expected: PASS (4 tests).

- [ ] **Step 5: Implement `SystemSampler` (live data)**

`Sources/MacNotch/Modules/System/SystemSampler.swift`:

```swift
import Foundation
import IOKit.ps

public enum SystemSampler {
    public static func sample() -> SystemSample {
        let (pct, charging) = battery()
        return SystemSample(batteryPercent: pct, isCharging: charging,
                            cpuPercent: cpuUsage(), ramUsedBytes: ramUsed())
    }

    private static func battery() -> (Int?, Bool) {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
              let first = list.first,
              let desc = IOPSGetPowerSourceDescription(blob, first)?.takeUnretainedValue()
                as? [String: Any]
        else { return (nil, false) }
        let cur = desc[kIOPSCurrentCapacityKey] as? Int
        let max = desc[kIOPSMaxCapacityKey] as? Int ?? 100
        let state = desc[kIOPSPowerSourceStateKey] as? String
        let pct = cur.map { Int((Double($0) / Double(max) * 100).rounded()) }
        return (pct, state == kIOPSACPowerValue)
    }

    private static func ramUsed() -> UInt64 {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }
        let page = UInt64(vm_kernel_page_size)
        return (UInt64(stats.active_count) + UInt64(stats.wire_count)) * page
    }

    private static func cpuUsage() -> Double {
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let kr = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }
        let user = Double(load.cpu_ticks.0), sys = Double(load.cpu_ticks.1)
        let idle = Double(load.cpu_ticks.2), nice = Double(load.cpu_ticks.3)
        let busy = user + sys + nice, total = busy + idle
        return total > 0 ? (busy / total * 100) : 0
    }
}
```

> Note: this returns cumulative CPU since boot (a coarse number). A delta-based sampler is a later refinement; the formatting/tests above don't depend on it.

- [ ] **Step 6: Implement views + module**

`Sources/MacNotch/Modules/System/SystemViews.swift`:

```swift
import SwiftUI

struct SystemExpandedView: View {
    let sample: SystemSample
    var body: some View {
        HStack {
            Label(sample.batteryLabel, systemImage: "battery.100")
                .foregroundStyle(.white)
            Spacer()
            Text("CPU \(sample.cpuLabel)  RAM \(sample.ramLabel)")
                .foregroundStyle(.white.opacity(0.6))
        }
        .font(.system(size: 11, weight: .medium))
    }
}
```

`Sources/MacNotch/Modules/System/SystemModule.swift`:

```swift
import SwiftUI

@MainActor
final class SystemModule: NotchModule {
    let id = "system"
    let title = "Battery & System"
    var isEnabled = true

    private var sample = SystemSample(batteryPercent: nil, isCharging: false,
                                      cpuPercent: 0, ramUsedBytes: 0)
    private var timer: Timer?
    private let state = StateBox()
    final class StateBox: ObservableObject { @Published var sample = SystemSample(
        batteryPercent: nil, isCharging: false, cpuPercent: 0, ramUsedBytes: 0) }

    func collapsedView() -> AnyView? { nil }

    func expandedView() -> AnyView {
        AnyView(_SystemBridge(box: state))
    }

    func activate() {
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }
    func deactivate() { timer?.invalidate(); timer = nil }

    func refresh() async {
        let s = SystemSampler.sample()
        await MainActor.run { self.state.sample = s }
    }
}

private struct _SystemBridge: View {
    @ObservedObject var box: SystemModule.StateBox
    var body: some View { SystemExpandedView(sample: box.sample) }
}
```

- [ ] **Step 7: Register the module**

In `Sources/MacNotch/App/AppDelegate.swift`, replace `registerModules()` body:

```swift
private func registerModules() {
    registry.register(SystemModule())
}
```

- [ ] **Step 8: Build + manual verification**

Run: `swift test && make run`
Expected: tests pass; expanding the notch shows a live "battery / CPU / RAM" row that updates every ~3s.

- [ ] **Step 9: Commit**

```bash
git add Sources/MacNotch/Modules/System Tests/MacNotchTests/SystemSampleTests.swift Sources/MacNotch/App/AppDelegate.swift
git commit -m "Add System module (battery/CPU/RAM) with tested formatting"
```

---

### Task 10: Media module (`MediaSource` hedge: AppleScript + opportunistic MediaRemote)

**Files:**
- Create: `Sources/MacNotch/Modules/Media/NowPlaying.swift`
- Create: `Sources/MacNotch/Modules/Media/MediaSource.swift`
- Create: `Sources/MacNotch/Modules/Media/MediaController.swift`
- Create: `Sources/MacNotch/Modules/Media/AppleScriptSource.swift`
- Create: `Sources/MacNotch/Modules/Media/MediaRemoteSource.swift`
- Create: `Sources/MacNotch/Modules/Media/MediaViews.swift`
- Create: `Sources/MacNotch/Modules/Media/MediaModule.swift`
- Modify: `Sources/MacNotch/App/AppDelegate.swift:registerModules`
- Test: `Tests/MacNotchTests/MediaControllerTests.swift`

**Interfaces:**
- Produces:
  - `struct NowPlaying: Equatable { var title: String; var artist: String; var app: String; var isPlaying: Bool; var elapsed: Double?; var duration: Double? }`
  - `protocol MediaSource: AnyObject { var name: String { get }; var isAvailable: Bool { get }; func nowPlaying() -> NowPlaying?; func playPause(); func next(); func previous() }`
  - `final class MediaController` init `(sources: [MediaSource])`; `func active() -> (source: MediaSource, np: NowPlaying)?`; selection: prefer an available source whose `nowPlaying()?.isPlaying == true`, else first available with any track, in array order.
  - `final class AppleScriptSource` (one instance for Music, one for Spotify), `final class MediaRemoteSource`, `final class MediaModule: NotchModule`.

- [ ] **Step 1: Write failing tests (selection logic with fakes)**

`Tests/MacNotchTests/MediaControllerTests.swift`:

```swift
import XCTest
@testable import MacNotch

final class MediaControllerTests: XCTestCase {
    final class Fake: MediaSource {
        let name: String; var isAvailable: Bool; var np: NowPlaying?
        init(_ name: String, available: Bool, np: NowPlaying?) {
            self.name = name; self.isAvailable = available; self.np = np
        }
        func nowPlaying() -> NowPlaying? { isAvailable ? np : nil }
        func playPause() {}; func next() {}; func previous() {}
    }
    private func np(_ title: String, playing: Bool) -> NowPlaying {
        NowPlaying(title: title, artist: "x", app: "x", isPlaying: playing,
                   elapsed: nil, duration: nil)
    }

    func testPrefersPlayingSource() {
        let paused = Fake("Music", available: true, np: np("A", playing: false))
        let playing = Fake("Spotify", available: true, np: np("B", playing: true))
        let c = MediaController(sources: [paused, playing])
        XCTAssertEqual(c.active()?.np.title, "B")
    }

    func testFallsBackToAnyTrackWhenNonePlaying() {
        let paused = Fake("Music", available: true, np: np("A", playing: false))
        let c = MediaController(sources: [paused])
        XCTAssertEqual(c.active()?.np.title, "A")
    }

    func testIgnoresUnavailableSources() {
        let dead = Fake("MR", available: false, np: np("Z", playing: true))
        let live = Fake("Music", available: true, np: np("A", playing: false))
        let c = MediaController(sources: [dead, live])
        XCTAssertEqual(c.active()?.source.name, "Music")
    }

    func testReturnsNilWhenNothingAvailable() {
        let c = MediaController(sources: [Fake("MR", available: false, np: nil)])
        XCTAssertNil(c.active())
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --filter MediaControllerTests`
Expected: FAIL — undefined types.

- [ ] **Step 3: Implement `NowPlaying`, `MediaSource`, `MediaController`**

`Sources/MacNotch/Modules/Media/NowPlaying.swift`:

```swift
import Foundation

public struct NowPlaying: Equatable {
    public var title: String
    public var artist: String
    public var app: String
    public var isPlaying: Bool
    public var elapsed: Double?
    public var duration: Double?

    public init(title: String, artist: String, app: String, isPlaying: Bool,
                elapsed: Double?, duration: Double?) {
        self.title = title; self.artist = artist; self.app = app
        self.isPlaying = isPlaying; self.elapsed = elapsed; self.duration = duration
    }

    public var progress: Double? {
        guard let e = elapsed, let d = duration, d > 0 else { return nil }
        return min(max(e / d, 0), 1)
    }
}
```

`Sources/MacNotch/Modules/Media/MediaSource.swift`:

```swift
import Foundation

public protocol MediaSource: AnyObject {
    var name: String { get }
    var isAvailable: Bool { get }
    func nowPlaying() -> NowPlaying?
    func playPause()
    func next()
    func previous()
}
```

`Sources/MacNotch/Modules/Media/MediaController.swift`:

```swift
import Foundation

public final class MediaController {
    private let sources: [MediaSource]
    public init(sources: [MediaSource]) { self.sources = sources }

    /// Prefer an available source that is currently playing; else any with a track.
    public func active() -> (source: MediaSource, np: NowPlaying)? {
        let live = sources.filter { $0.isAvailable }
        if let playing = live.first(where: { $0.nowPlaying()?.isPlaying == true }),
           let np = playing.nowPlaying() {
            return (playing, np)
        }
        for s in live { if let np = s.nowPlaying() { return (s, np) } }
        return nil
    }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `swift test --filter MediaControllerTests`
Expected: PASS (4 tests).

- [ ] **Step 5: Implement `AppleScriptSource`**

`Sources/MacNotch/Modules/Media/AppleScriptSource.swift`:

```swift
import AppKit

/// Drives Music.app or Spotify.app via AppleScript. Reliable, entitlement-gated by
/// Automation TCC. `appName` is "Music" or "Spotify".
public final class AppleScriptSource: MediaSource {
    public let name: String
    private let appName: String
    public init(appName: String) { self.appName = appName; self.name = appName }

    public var isAvailable: Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleID
        }
    }
    private var bundleID: String {
        appName == "Music" ? "com.apple.Music" : "com.spotify.client"
    }

    public func nowPlaying() -> NowPlaying? {
        guard isAvailable else { return nil }
        let script = """
        tell application "\(appName)"
            if it is running then
                set st to player state as text
                set t to name of current track
                set a to artist of current track
                set pos to player position
                set dur to (duration of current track)
                return st & "\\n" & t & "\\n" & a & "\\n" & pos & "\\n" & dur
            end if
        end tell
        """
        guard let out = run(script) else { return nil }
        let parts = out.components(separatedBy: "\n")
        guard parts.count >= 5 else { return nil }
        let playing = parts[0].contains("playing")
        let elapsed = Double(parts[3])
        // Spotify duration is ms; Music is seconds.
        let rawDur = Double(parts[4])
        let duration = (appName == "Spotify") ? rawDur.map { $0 / 1000 } : rawDur
        return NowPlaying(title: parts[1], artist: parts[2], app: appName,
                          isPlaying: playing, elapsed: elapsed, duration: duration)
    }

    public func playPause() { _ = run("tell application \"\(appName)\" to playpause") }
    public func next()      { _ = run("tell application \"\(appName)\" to next track") }
    public func previous()  { _ = run("tell application \"\(appName)\" to previous track") }

    @discardableResult
    private func run(_ source: String) -> String? {
        var err: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&err)
        if err != nil { return nil }
        return result?.stringValue
    }
}
```

- [ ] **Step 6: Implement `MediaRemoteSource` (opportunistic stub)**

`Sources/MacNotch/Modules/Media/MediaRemoteSource.swift`:

```swift
import Foundation

/// Opportunistic private-framework source. On macOS 15.4+/26 this is expected to be
/// unavailable; it reports `isAvailable == false` and is skipped. Kept behind the
/// MediaSource seam so a working backend can be dropped in later with no caller changes.
public final class MediaRemoteSource: MediaSource {
    public let name = "MediaRemote"
    public var isAvailable: Bool { false } // not wired in Phase 1
    public func nowPlaying() -> NowPlaying? { nil }
    public func playPause() {}
    public func next() {}
    public func previous() {}
}
```

- [ ] **Step 7: Implement views + module**

`Sources/MacNotch/Modules/Media/MediaViews.swift`:

```swift
import SwiftUI

struct MediaExpandedView: View {
    let np: NowPlaying?
    let onPrev: () -> Void, onPlayPause: () -> Void, onNext: () -> Void

    var body: some View {
        if let np {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.pink, .purple],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(np.title).foregroundStyle(.white)
                            .font(.system(size: 12, weight: .medium)).lineLimit(1)
                        Text("\(np.artist) · \(np.app)").foregroundStyle(.white.opacity(0.6))
                            .font(.system(size: 10)).lineLimit(1)
                    }
                    Spacer()
                }
                HStack(spacing: 22) {
                    Button(action: onPrev) { Image(systemName: "backward.fill") }
                    Button(action: onPlayPause) {
                        Image(systemName: np.isPlaying ? "pause.fill" : "play.fill")
                    }
                    Button(action: onNext) { Image(systemName: "forward.fill") }
                }
                .buttonStyle(.plain).foregroundStyle(.white).font(.system(size: 13))
                .frame(maxWidth: .infinity)
                if let p = np.progress {
                    ProgressView(value: p).tint(.white)
                }
            }
        } else {
            Text("Nothing playing").foregroundStyle(.white.opacity(0.5))
                .font(.system(size: 11))
        }
    }
}
```

`Sources/MacNotch/Modules/Media/MediaModule.swift`:

```swift
import SwiftUI

@MainActor
final class MediaModule: NotchModule {
    let id = "media"
    let title = "Now Playing"
    var isEnabled = true

    private let controller = MediaController(sources: [
        MediaRemoteSource(),
        AppleScriptSource(appName: "Music"),
        AppleScriptSource(appName: "Spotify"),
    ])
    private var timer: Timer?
    final class Box: ObservableObject { @Published var np: NowPlaying? }
    private let box = Box()

    func collapsedView() -> AnyView? {
        AnyView(_MediaCollapsed(box: box))
    }
    func expandedView() -> AnyView {
        AnyView(_MediaExpanded(box: box, controller: controller, refresh: { [weak self] in
            Task { await self?.refresh() }
        }))
    }

    func activate() {
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }
    func deactivate() { timer?.invalidate(); timer = nil }

    func refresh() async {
        let np = controller.active()?.np
        await MainActor.run { self.box.np = np }
    }

    var controllerForViews: MediaController { controller }
}

private struct _MediaCollapsed: View {
    @ObservedObject var box: MediaModule.Box
    var body: some View {
        if box.np?.isPlaying == true {
            Image(systemName: "waveform").foregroundStyle(.white).font(.system(size: 10))
        }
    }
}

private struct _MediaExpanded: View {
    @ObservedObject var box: MediaModule.Box
    let controller: MediaController
    let refresh: () -> Void
    var body: some View {
        MediaExpandedView(
            np: box.np,
            onPrev: { controller.active()?.source.previous(); refresh() },
            onPlayPause: { controller.active()?.source.playPause(); refresh() },
            onNext: { controller.active()?.source.next(); refresh() })
    }
}
```

- [ ] **Step 8: Register the module**

In `registerModules()`:

```swift
private func registerModules() {
    registry.register(MediaModule())
    registry.register(SystemModule())
}
```

- [ ] **Step 9: Build + manual verification**

Run: `swift test && make run`
Expected: tests pass. Start Music or Spotify and play a track; expand the notch — title/artist appear and play/pause/next control the app (grant Automation permission when prompted). With nothing playing, shows "Nothing playing".

- [ ] **Step 10: Commit**

```bash
git add Sources/MacNotch/Modules/Media Tests/MacNotchTests/MediaControllerTests.swift Sources/MacNotch/App/AppDelegate.swift
git commit -m "Add Media module with AppleScript sources behind MediaSource seam"
```

---

### Task 11: Calendar module (EventKit)

**Files:**
- Create: `Sources/MacNotch/Modules/Calendar/CalendarModule.swift`
- Create: `Sources/MacNotch/Modules/Calendar/CalendarViews.swift`
- Modify: `Sources/MacNotch/App/AppDelegate.swift:registerModules`
- Test: `Tests/MacNotchTests/CalendarFormatTests.swift`

**Interfaces:**
- Produces:
  - `struct CalEvent: Equatable { var title: String; var start: Date; var colorHex: String? }`
  - `enum CalendarFormat { static func timeLabel(_ date: Date, calendar: Calendar) -> String; static func dayHeader(_ date: Date, calendar: Calendar) -> String; static func upcoming(_ events: [CalEvent], now: Date, limit: Int) -> [CalEvent] }` (pure — tested)
  - `final class CalendarModule: NotchModule`

- [ ] **Step 1: Write failing tests (pure formatting/filtering)**

`Tests/MacNotchTests/CalendarFormatTests.swift`:

```swift
import XCTest
@testable import MacNotch

final class CalendarFormatTests: XCTestCase {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func date(_ h: Int, _ m: Int) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 6, day: 22, hour: h, minute: m))!
    }

    func testUpcomingFiltersPastAndLimits() {
        let now = date(12, 0)
        let events = [
            CalEvent(title: "past", start: date(9, 0), colorHex: nil),
            CalEvent(title: "soon", start: date(13, 0), colorHex: nil),
            CalEvent(title: "later", start: date(16, 0), colorHex: nil),
            CalEvent(title: "evening", start: date(19, 0), colorHex: nil),
        ]
        let up = CalendarFormat.upcoming(events, now: now, limit: 2)
        XCTAssertEqual(up.map(\.title), ["soon", "later"])
    }

    func testTimeLabelIs24hPadded() {
        XCTAssertEqual(CalendarFormat.timeLabel(date(9, 5), calendar: cal), "09:05")
        XCTAssertEqual(CalendarFormat.timeLabel(date(13, 30), calendar: cal), "13:30")
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --filter CalendarFormatTests`
Expected: FAIL — undefined types.

- [ ] **Step 3: Implement model + formatting**

`Sources/MacNotch/Modules/Calendar/CalendarModule.swift` (model + pure format first; module class added in step 5):

```swift
import EventKit
import SwiftUI

public struct CalEvent: Equatable {
    public var title: String
    public var start: Date
    public var colorHex: String?
    public init(title: String, start: Date, colorHex: String?) {
        self.title = title; self.start = start; self.colorHex = colorHex
    }
}

public enum CalendarFormat {
    public static func timeLabel(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }
    public static func dayHeader(_ date: Date, calendar: Calendar) -> String {
        let f = DateFormatter(); f.calendar = calendar
        f.timeZone = calendar.timeZone; f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
    public static func upcoming(_ events: [CalEvent], now: Date, limit: Int) -> [CalEvent] {
        events.filter { $0.start >= now }.sorted { $0.start < $1.start }.prefix(limit).map { $0 }
    }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `swift test --filter CalendarFormatTests`
Expected: PASS (2 tests).

- [ ] **Step 5: Implement the EventKit-backed module**

Append to `Sources/MacNotch/Modules/Calendar/CalendarModule.swift`:

```swift
@MainActor
final class CalendarModule: NotchModule {
    let id = "calendar"
    let title = "Calendar"
    var isEnabled = true

    private let store = EKEventStore()
    final class Box: ObservableObject {
        @Published var events: [CalEvent] = []
        @Published var denied = false
    }
    let box = Box()

    func collapsedView() -> AnyView? { nil }
    func expandedView() -> AnyView { AnyView(CalendarExpandedView(box: box)) }

    func activate() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
                Task { await self?.refresh() }
            }
        Task { await refresh() }
    }
    func deactivate() {
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: store)
    }

    func refresh() async {
        let granted = (try? await store.requestFullAccessToEvents()) ?? false
        guard granted else { await MainActor.run { box.denied = true }; return }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let pred = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let mapped = store.events(matching: pred).map {
            CalEvent(title: $0.title ?? "Untitled", start: $0.startDate,
                     colorHex: nil)
        }
        let up = CalendarFormat.upcoming(mapped, now: Date(), limit: 4)
        await MainActor.run { box.denied = false; box.events = up }
    }
}
```

`Sources/MacNotch/Modules/Calendar/CalendarViews.swift`:

```swift
import SwiftUI

struct CalendarExpandedView: View {
    @ObservedObject var box: CalendarModule.Box
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(CalendarFormat.dayHeader(Date(), calendar: .current))
                .foregroundStyle(.white).font(.system(size: 11, weight: .medium))
            if box.denied {
                Button("Grant Calendar access") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.plain).foregroundStyle(.blue).font(.system(size: 10))
            } else if box.events.isEmpty {
                Text("Nothing left today").foregroundStyle(.white.opacity(0.5))
                    .font(.system(size: 10))
            } else {
                ForEach(box.events.indices, id: \.self) { i in
                    let e = box.events[i]
                    HStack(spacing: 6) {
                        Circle().fill(.cyan).frame(width: 5, height: 5)
                        Text(CalendarFormat.timeLabel(e.start, calendar: .current))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(e.title).foregroundStyle(.white.opacity(0.8)).lineLimit(1)
                    }
                    .font(.system(size: 10))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

- [ ] **Step 6: Register the module**

```swift
private func registerModules() {
    registry.register(MediaModule())
    registry.register(CalendarModule())
    registry.register(SystemModule())
}
```

- [ ] **Step 7: Build + manual verification**

Run: `swift test && make run`
Expected: tests pass. Expand the notch; on first run macOS prompts for Calendar access. After granting, today's upcoming events appear. Deny → a "Grant Calendar access" button that opens System Settings.

- [ ] **Step 8: Commit**

```bash
git add Sources/MacNotch/Modules/Calendar Tests/MacNotchTests/CalendarFormatTests.swift Sources/MacNotch/App/AppDelegate.swift
git commit -m "Add Calendar module with EventKit and tested formatting"
```

---

### Task 12: Drop Shelf module (`ShelfStore` bookmarks + drag-and-drop)

**Files:**
- Create: `Sources/MacNotch/Modules/Shelf/ShelfItem.swift`
- Create: `Sources/MacNotch/Modules/Shelf/ShelfStore.swift`
- Create: `Sources/MacNotch/Modules/Shelf/ShelfViews.swift`
- Create: `Sources/MacNotch/Modules/Shelf/ShelfModule.swift`
- Modify: `Sources/MacNotch/App/AppDelegate.swift:registerModules`
- Test: `Tests/MacNotchTests/ShelfStoreTests.swift`

**Interfaces:**
- Produces:
  - `struct ShelfItem: Codable, Equatable { var name: String; var bookmark: Data }`
  - `final class ShelfStore` init `(url: URL)`; `var items: [ShelfItem]`; `func add(_ fileURL: URL)`; `func remove(at index: Int)`; `func clear()`; `func resolve(_ item: ShelfItem) -> URL?`; `func isStale(_ item: ShelfItem) -> Bool`; persists to `url`.
  - `final class ShelfModule: NotchModule`

- [ ] **Step 1: Write failing tests (temp files)**

`Tests/MacNotchTests/ShelfStoreTests.swift`:

```swift
import XCTest
@testable import MacNotch

final class ShelfStoreTests: XCTestCase {
    private func tempStoreURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    }
    private func tempFile(_ name: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "-" + name)
        try? "hi".write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testAddPersistsAndResolves() {
        let storeURL = tempStoreURL()
        let file = tempFile("report.pdf")
        let a = ShelfStore(url: storeURL)
        a.add(file)
        XCTAssertEqual(a.items.count, 1)
        XCTAssertEqual(a.items[0].name, file.lastPathComponent)

        let b = ShelfStore(url: storeURL)        // reload from disk
        XCTAssertEqual(b.items.count, 1)
        XCTAssertEqual(b.resolve(b.items[0])?.lastPathComponent, file.lastPathComponent)
    }

    func testRemove() {
        let s = ShelfStore(url: tempStoreURL())
        s.add(tempFile("a.txt")); s.add(tempFile("b.txt"))
        s.remove(at: 0)
        XCTAssertEqual(s.items.count, 1)
        XCTAssertEqual(s.items[0].name.hasSuffix("b.txt"), true)
    }

    func testStaleDetectionForDeletedFile() {
        let s = ShelfStore(url: tempStoreURL())
        let file = tempFile("gone.txt")
        s.add(file)
        try? FileManager.default.removeItem(at: file)
        XCTAssertTrue(s.isStale(s.items[0]))
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --filter ShelfStoreTests`
Expected: FAIL — undefined types.

- [ ] **Step 3: Implement `ShelfItem` + `ShelfStore`**

`Sources/MacNotch/Modules/Shelf/ShelfItem.swift`:

```swift
import Foundation

public struct ShelfItem: Codable, Equatable {
    public var name: String
    public var bookmark: Data
    public init(name: String, bookmark: Data) { self.name = name; self.bookmark = bookmark }
}
```

`Sources/MacNotch/Modules/Shelf/ShelfStore.swift`:

```swift
import Foundation

public final class ShelfStore {
    public private(set) var items: [ShelfItem] = []
    private let url: URL

    public init(url: URL) {
        self.url = url
        load()
    }

    public func add(_ fileURL: URL) {
        guard let data = try? fileURL.bookmarkData(
            options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        else { return }
        items.append(ShelfItem(name: fileURL.lastPathComponent, bookmark: data))
        save()
    }

    public func remove(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index); save()
    }

    public func clear() { items.removeAll(); save() }

    public func resolve(_ item: ShelfItem) -> URL? {
        var stale = false
        return try? URL(resolvingBookmarkData: item.bookmark,
                        options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
    }

    public func isStale(_ item: ShelfItem) -> Bool {
        guard let url = resolve(item) else { return true }
        return !FileManager.default.fileExists(atPath: url.path)
    }

    private func load() {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ShelfItem].self, from: data)
        else { return }
        items = decoded
    }

    private func save() {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: url, options: .atomic)
        }
    }

    public static func defaultURL() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MacNotch/shelf.json")
    }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `swift test --filter ShelfStoreTests`
Expected: PASS (3 tests).

- [ ] **Step 5: Implement views (drag-in destination + drag-out chips)**

`Sources/MacNotch/Modules/Shelf/ShelfViews.swift`:

```swift
import SwiftUI
import UniformTypeIdentifiers

struct ShelfExpandedView: View {
    @ObservedObject var box: ShelfModule.Box
    let onDrop: ([URL]) -> Void
    let onRemove: (Int) -> Void
    let resolve: (ShelfItem) -> URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DROP SHELF").foregroundStyle(.white.opacity(0.4))
                .font(.system(size: 9, weight: .medium)).tracking(0.5)
            if box.items.isEmpty {
                Text("Drop files here").foregroundStyle(.white.opacity(0.4))
                    .font(.system(size: 10))
                    .frame(maxWidth: .infinity, minHeight: 28)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(box.items.indices, id: \.self) { i in
                            chip(box.items[i], index: i)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dropDestination(for: URL.self) { urls, _ in onDrop(urls); return true }
    }

    private func chip(_ item: ShelfItem, index: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.fill").font(.system(size: 9)).foregroundStyle(.white.opacity(0.7))
            Text(item.name).font(.system(size: 9)).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(RoundedRectangle(cornerRadius: 5).fill(.white.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.08)))
        .draggable(resolve(item) ?? URL(fileURLWithPath: "/"))
        .contextMenu { Button("Remove") { onRemove(index) } }
    }
}
```

`Sources/MacNotch/Modules/Shelf/ShelfModule.swift`:

```swift
import SwiftUI

@MainActor
final class ShelfModule: NotchModule {
    let id = "shelf"
    let title = "Drop Shelf"
    var isEnabled = true

    private let store = ShelfStore(url: ShelfStore.defaultURL())
    final class Box: ObservableObject { @Published var items: [ShelfItem] = [] }
    let box = Box()

    init() { box.items = store.items }

    func collapsedView() -> AnyView? {
        AnyView(_ShelfBadge(box: box))
    }
    func expandedView() -> AnyView {
        AnyView(ShelfExpandedView(
            box: box,
            onDrop: { [weak self] urls in
                guard let self else { return }
                urls.forEach { self.store.add($0) }
                self.box.items = self.store.items
            },
            onRemove: { [weak self] i in
                guard let self else { return }
                self.store.remove(at: i); self.box.items = self.store.items
            },
            resolve: { [weak self] in self?.store.resolve($0) }))
    }

    func activate() { box.items = store.items }
    func deactivate() {}
    func refresh() async {}
}

private struct _ShelfBadge: View {
    @ObservedObject var box: ShelfModule.Box
    var body: some View {
        if !box.items.isEmpty {
            Text("\(box.items.count)")
                .font(.system(size: 9, weight: .medium)).foregroundStyle(.white)
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(Capsule().fill(.white.opacity(0.15)))
        }
    }
}
```

- [ ] **Step 6: Register the module (final order)**

```swift
private func registerModules() {
    registry.register(MediaModule())
    registry.register(CalendarModule())
    registry.register(SystemModule())
    registry.register(ShelfModule())
}
```

- [ ] **Step 7: Build + manual verification**

Run: `swift test && make run`
Expected: tests pass. Expand the notch and drag a file from Finder onto the panel → a chip appears; it survives a relaunch; drag the chip back into a Finder window → the original file is referenced; right-click a chip → Remove.

- [ ] **Step 8: Commit**

```bash
git add Sources/MacNotch/Modules/Shelf Tests/MacNotchTests/ShelfStoreTests.swift Sources/MacNotch/App/AppDelegate.swift
git commit -m "Add Drop Shelf module with security-scoped bookmarks"
```

---

### Task 13: Settings window + launch-at-login

**Files:**
- Create: `Sources/MacNotch/App/LoginItem.swift`
- Create: `Sources/MacNotch/App/SettingsView.swift`
- Create: `Sources/MacNotch/App/SettingsWindowController.swift`
- Modify: `Sources/MacNotch/App/AppDelegate.swift`
- Test: `Tests/MacNotchTests/LoginItemTests.swift`

**Interfaces:**
- Consumes: `SettingsStore` (Task 4), `ModuleRegistry` (Task 5).
- Produces:
  - `enum LoginItem { static func isEnabled() -> Bool; static func setEnabled(_ on: Bool) }` (wraps `SMAppService.mainApp`)
  - `struct SettingsView: View` bound to `SettingsStore` + module titles; toggles enable/disable, drag-to-reorder, launch-at-login.
  - `@MainActor final class SettingsWindowController` with `func show()`.
  - A pure helper `enum SettingsLogic { static func toggle(_ settings: inout AppSettings, id: String, on: Bool); static func reorder(_ settings: inout AppSettings, from: Int, to: Int) }` (tested).

- [ ] **Step 1: Write failing test (pure reorder/toggle helper)**

`Tests/MacNotchTests/LoginItemTests.swift`:

```swift
import XCTest
@testable import MacNotch

final class SettingsLogicTests: XCTestCase {
    func testToggleFlipsEnabled() {
        var s = AppSettings.defaults
        SettingsLogic.toggle(&s, id: "media", on: false)
        XCTAssertFalse(s.modules.first { $0.id == "media" }!.isEnabled)
    }
    func testReorderMovesIndices() {
        var s = AppSettings.defaults
        let firstID = s.modules[0].id
        SettingsLogic.reorder(&s, from: 0, to: 3)
        XCTAssertEqual(s.modules[3].id, firstID)
    }
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --filter SettingsLogicTests`
Expected: FAIL — `SettingsLogic` undefined.

- [ ] **Step 3: Implement `SettingsLogic` + `LoginItem`**

`Sources/MacNotch/App/LoginItem.swift`:

```swift
import Foundation
import ServiceManagement

public enum SettingsLogic {
    public static func toggle(_ settings: inout AppSettings, id: String, on: Bool) {
        guard let i = settings.modules.firstIndex(where: { $0.id == id }) else { return }
        settings.modules[i].isEnabled = on
    }
    public static func reorder(_ settings: inout AppSettings, from: Int, to: Int) {
        guard settings.modules.indices.contains(from) else { return }
        let item = settings.modules.remove(at: from)
        settings.modules.insert(item, at: max(0, min(to, settings.modules.count)))
    }
}

public enum LoginItem {
    public static func isEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }
    public static func setEnabled(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch { NSLog("LoginItem error: \(error)") }
    }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `swift test --filter SettingsLogicTests`
Expected: PASS (2 tests).

- [ ] **Step 5: Implement `SettingsView`**

`Sources/MacNotch/App/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @State var settings: AppSettings
    let titles: [String: String]       // module id → display title
    let onChange: (AppSettings) -> Void

    var body: some View {
        Form {
            Section("Modules (drag to reorder)") {
                List {
                    ForEach(settings.modules, id: \.id) { m in
                        Toggle(titles[m.id] ?? m.id, isOn: Binding(
                            get: { m.isEnabled },
                            set: { on in
                                SettingsLogic.toggle(&settings, id: m.id, on: on)
                                onChange(settings)
                            }))
                    }
                    .onMove { idx, dest in
                        if let from = idx.first {
                            SettingsLogic.reorder(&settings, from: from,
                                                  to: dest > from ? dest - 1 : dest)
                            onChange(settings)
                        }
                    }
                }
                .frame(height: 160)
            }
            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { on in
                        settings.launchAtLogin = on
                        LoginItem.setEnabled(on)
                        onChange(settings)
                    }))
            }
        }
        .padding(20).frame(width: 360)
    }
}
```

`Sources/MacNotch/App/SettingsWindowController.swift`:

```swift
import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    private let settings: SettingsStore
    private let titles: [String: String]
    private let onChange: (AppSettings) -> Void

    init(settings: SettingsStore, titles: [String: String], onChange: @escaping (AppSettings) -> Void) {
        self.settings = settings; self.titles = titles; self.onChange = onChange
    }

    func show() {
        if window == nil {
            let view = SettingsView(settings: settings.settings, titles: titles,
                                    onChange: onChange)
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 320),
                             styleMask: [.titled, .closable], backing: .buffered, defer: false)
            w.title = "MacNotch Settings"
            w.contentView = NSHostingView(rootView: view)
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
```

- [ ] **Step 6: Wire settings into `AppDelegate` + persist + live-apply**

In `AppDelegate`, add a `NotchWindow.reload()` path and wire the menu. Add to `NotchWindow`:

```swift
// In NotchWindow:
public func reload() {
    for m in orderedModules() { m.activate() }
}
```

Update `applicationDidFinishLaunching` tail:

```swift
let titles = ["media": "Now Playing", "calendar": "Calendar",
              "system": "Battery & System", "shelf": "Drop Shelf"]
let settingsWC = SettingsWindowController(settings: settings, titles: titles) { [weak self] updated in
    self?.settings.settings = updated
    self?.settings.save()
    self?.notch?.reload()
}
self.settingsWC = settingsWC
menuBar.onOpenSettings = { settingsWC.show() }
```

Add stored property `private var settingsWC: SettingsWindowController?` and make `settings.settings` settable (it already is via `setEnabled`/`move`; add a public setter):

In `SettingsStore`, add:
```swift
public func replace(_ new: AppSettings) { settings = new }
```
and call `self?.settings.replace(updated)` instead of assigning directly.

- [ ] **Step 7: Build + manual verification**

Run: `swift test && make run`
Expected: tests pass. Menu → "Open Settings…" opens a window listing the four modules with toggles and drag-to-reorder, plus "Launch at login". Toggling a module off removes it from the notch immediately; reordering changes the stack order; enabling launch-at-login registers the app (verify in System Settings → General → Login Items).

- [ ] **Step 8: Commit**

```bash
git add Sources/MacNotch/App/LoginItem.swift Sources/MacNotch/App/SettingsView.swift Sources/MacNotch/App/SettingsWindowController.swift Sources/MacNotch/App/AppDelegate.swift Sources/MacNotch/Window/NotchWindow.swift Sources/MacNotch/App/SettingsStore.swift Tests/MacNotchTests/LoginItemTests.swift
git commit -m "Add settings window, module reorder, and launch-at-login"
```

---

### Task 14: README + manual test checklist + final pass

**Files:**
- Create: `README.md`

**Interfaces:** none.

- [ ] **Step 1: Write `README.md`**

````markdown
# MacNotch (personal build)

A native macOS notch dashboard: a borderless panel that hugs the notch and expands
into modules — Now Playing, Calendar, Battery/System, and a Drop Shelf.

## Requirements
- macOS 14+ (built/run on macOS 26, Apple Silicon)
- Swift 6 toolchain (Command Line Tools). **No Xcode required.**

## Build & run
```bash
make test     # run unit tests
make run      # build, package MacNotch.app, and launch it
```
The app runs as a menu-bar agent (no Dock icon). Use the menu-bar icon for
Settings / Toggle Notch / Quit.

## Permissions
- **Calendar** — prompted on first expand (EventKit).
- **Automation (Music/Spotify)** — prompted on first media control.
- Ad-hoc signing means TCC may re-prompt after a rebuild; re-grant if so.

## Manual test checklist
- [ ] Notch shape sits under the physical notch; expands on hover, collapses on exit.
- [ ] Now Playing shows track + controls Music/Spotify.
- [ ] Calendar shows today's events after access is granted.
- [ ] Battery/CPU/RAM update live.
- [ ] Drag a file onto the panel → chip appears, survives relaunch, drags back to Finder.
- [ ] Settings toggles/reorders modules; launch-at-login registers in Login Items.

## Architecture
See `docs/superpowers/specs/2026-06-22-macnotch-phase1-design.md`.
Modules conform to `NotchModule`; the window renders whatever is enabled, in order.
````

- [ ] **Step 2: Full test + build sweep**

Run: `swift test && make package`
Expected: all tests pass; `build/MacNotch.app` builds and signs cleanly.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Add README with build steps and manual test checklist"
```

---

## Self-Review (completed against the spec)

- **Spec coverage:** notch shell + state machine (T3, T8), notch geometry/fallback (T7),
  module protocol/seam (T5), Media with AppleScript + opportunistic MediaRemote behind
  `MediaSource` (T10), Calendar/EventKit (T11), Battery/System IOKit (T9), Drop Shelf
  with bookmarks (T12), menu-bar agent (T6), settings + reorder + launch-at-login (T13),
  no-Xcode SPM build/packaging + Info.plist usage strings + ad-hoc signing (T1, T2),
  README + manual checklist (T14). All §1 success criteria map to a task.
- **Placeholder scan:** no TBD/TODO; every code step contains complete code. The two
  "wired in later task" comments (T6/T8) are real forward references resolved in T8/T13,
  not placeholders.
- **Type consistency:** `NotchModule` (collapsedView/expandedView/activate/deactivate/
  refresh) is used identically across T5/T9/T10/T11/T12; `MediaSource`, `MediaController.active()`,
  `ShelfStore`, `SettingsStore`, `ScreenLocator.notchRect` signatures match their call sites.
- **Known coarse spots (acceptable for P1, noted in-plan):** CPU% is cumulative-since-boot
  (T9 note); hover hot-zone covers the full expanded footprint (T8 note); MediaRemote is a
  disabled stub (T10) — all per the spec's deferred/refinement scope.
