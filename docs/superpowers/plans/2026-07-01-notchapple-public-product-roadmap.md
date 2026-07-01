# NotchApple Public Product Roadmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Evolve the existing MacNotch app into NotchApple, a public, polished, direct-download macOS productivity hub with a real design system, accessible UI, creative expansion gates, and a repeatable release path.

**Architecture:** Keep the current Swift Package architecture: `MacNotchKit` owns app logic and UI, `MacNotch` is the thin executable target, `ModuleRegistry` composes `NotchModule` features, and `AppSettings` remains the persisted settings root. Add brand, appearance, onboarding, migration, feature-flag, profile, and shared UI seams around the existing modules instead of rebuilding the app.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Swift Package Manager, custom executable test harness in `Sources/MacNotchTests`, shell packaging scripts, direct-download macOS distribution.

## Global Constraints

- Product name: `NotchApple`.
- Public bundle identifier: `io.notchapple.NotchApple`.
- Public executable and packaged app name: `NotchApple` in Phase 1.
- Internal library and test target names may remain `MacNotchKit` and `MacNotchTests` during the first public-product pass.
- Direct download first; Mac App Store readiness is deferred.
- Do not rebuild the app from scratch.
- Preserve `AppSettings`, `ModuleRegistry`, `NotchModule`, `NotchRootView`, `DashboardLayoutView`, and `WideBarLayoutView` unless a task explicitly changes them.
- Every shipped surface must include accessibility and error-state acceptance criteria.
- New features must be tagged Launch Core, Launch Optional, Creative Labs, or Reject/Defer before implementation.
- Launch Core creative candidates: Workspace Profiles and Command Palette.
- Launch Optional creative candidates: Focus Mode / Session Hub, AI Workbench, and Drop Actions.
- Creative Labs candidates: Notification Triage, Meeting Mode, Clipboard Studio, System Pulse, and any additional Fable-generated concepts.
- Reduced motion must override expressive animation choices.
- Built-in appearance presets must pass contrast checks before public release.
- Paper theme ships only after Studio Glass, Minimal Graphite, Aurora, and Terminal pass visual and contrast checks; otherwise Paper remains hidden.

---

## Scope Note

This is a master implementation plan for the NotchApple public-product goal. Tasks 1-15 produce the public launch spine and the two Launch Core creative features. Launch Optional modules are gated in Task 12 and should each receive a focused sub-plan before implementation.

## File Structure Map

- Create `Sources/MacNotchKit/App/NotchBrand.swift`: public product name, bundle id, storage names, user agent, and visible copy constants.
- Create `Sources/MacNotchTests/NotchBrandTests.swift`: brand constant tests.
- Modify `Sources/MacNotchTests/main.swift`: register new test files.
- Modify `Sources/MacNotchKit/App/AppCore.swift`: expose version, bundle id, and display name through `NotchBrand`.
- Modify `Sources/MacNotchKit/App/MenuBarController.swift`: NotchApple menu copy and accessibility.
- Modify `Sources/MacNotchKit/App/SettingsWindowController.swift`: NotchApple title and larger settings window.
- Modify `Sources/MacNotchKit/UI/DashboardLayoutView.swift`: NotchApple header, accessibility, keyboard pagination.
- Modify `Sources/MacNotchKit/Modules/Customize/CustomizeViews.swift`: Design Studio entry point.
- Modify `Scripts/package-app.sh`: NotchApple bundle, executable, usage descriptions, DMG naming.
- Modify `Makefile`: NotchApple run/package paths.
- Create `Sources/MacNotchKit/App/AppDataLocations.swift`: Application Support paths for old and new product identities.
- Create `Sources/MacNotchKit/App/AppDataMigrator.swift`: one-time MacNotch to NotchApple data migration.
- Create `Sources/MacNotchTests/AppDataMigratorTests.swift`: idempotent migration tests.
- Modify stores that currently hard-code `MacNotch`: `SettingsStore.swift`, `ShelfStore.swift`, `CodeProjectStore.swift`, `LauncherStore.swift`, `RemindersStore.swift`, `ClipboardStore.swift`, `ScreenTimeModule.swift`.
- Create `Sources/MacNotchKit/App/NotchAppearance.swift`: appearance model, presets, tokens, validation.
- Create `Sources/MacNotchTests/NotchAppearanceTests.swift`: defaults, codable, preset, and reduced-motion tests.
- Modify `Sources/MacNotchKit/App/AppSettings.swift`: persist `appearance` and future `activeWorkspaceProfileID`.
- Move or replace `NotchTheme` from `Sources/MacNotchKit/UI/DashboardTileChrome.swift` with `Sources/MacNotchKit/UI/NotchTheme.swift`.
- Create `Sources/MacNotchKit/UI/NotchControls.swift`: shared button, icon button, segmented control, toggle, and focus ring.
- Create `Sources/MacNotchKit/UI/ModuleStateViews.swift`: shared empty, loading, permission, offline, and error states.
- Create `Sources/MacNotchKit/App/SettingsSections.swift`: settings tab model.
- Create `Sources/MacNotchKit/App/DesignSettingsView.swift`: full Design tab.
- Create `Sources/MacNotchKit/App/OnboardingState.swift`: first-run and migration status.
- Create `Sources/MacNotchKit/App/OnboardingView.swift`: first-run trust and preset flow.
- Create `Sources/MacNotchTests/OnboardingStateTests.swift`: onboarding persistence and migration marker tests.
- Create `Sources/MacNotchKit/App/FeatureFlags.swift`: Launch Core, Launch Optional, and Creative Labs gates.
- Create `Sources/MacNotchTests/FeatureFlagsTests.swift`: flag default and categorization tests.
- Create `docs/creative/notchapple-creative-backlog.md`: ranked creative backlog.
- Create `Sources/MacNotchKit/App/WorkspaceProfile.swift`: profile model.
- Create `Sources/MacNotchKit/App/WorkspaceProfileStore.swift`: profile persistence.
- Create `Sources/MacNotchTests/WorkspaceProfileTests.swift`: profile defaults and switching tests.
- Create `Sources/MacNotchKit/Modules/CommandPalette/CommandPaletteModule.swift`: Launch Core command palette module.
- Create `Sources/MacNotchKit/Modules/CommandPalette/CommandPaletteViews.swift`: command palette UI.
- Create `Sources/MacNotchKit/Modules/CommandPalette/CommandPaletteModel.swift`: command registry and filtering.
- Create `Sources/MacNotchTests/CommandPaletteTests.swift`: command filtering and dispatch tests.
- Create `Scripts/notarize-app.sh`: direct-download notarization helper.
- Create `docs/release/notchapple-release-checklist.md`: final release checklist.

---

### Task 1: Brand Constants and Public Identity Seam

**Files:**
- Create: `Sources/MacNotchKit/App/NotchBrand.swift`
- Create: `Sources/MacNotchTests/NotchBrandTests.swift`
- Modify: `Sources/MacNotchKit/App/AppCore.swift`
- Modify: `Sources/MacNotchTests/main.swift`

**Interfaces:**
- Produces: `NotchBrand.productName: String`, `NotchBrand.settingsTitle: String`, `NotchBrand.quitMenuTitle: String`, `NotchBrand.bundleIdentifier: String`, `NotchBrand.applicationSupportDirectoryName: String`, `NotchBrand.legacyApplicationSupportDirectoryName: String`, `NotchBrand.userAgent: String`, `NotchBrand.affiliationDisclaimer: String`.
- Consumes: none.

- [ ] **Step 1: Write the failing brand tests**

Add `Sources/MacNotchTests/NotchBrandTests.swift`:

```swift
import MacNotchKit

func notchBrandTests() {
    test("NotchBrand exposes public product identity") {
        expectEqual(NotchBrand.productName, "NotchApple", "product name")
        expectEqual(NotchBrand.settingsTitle, "NotchApple Settings", "settings title")
        expectEqual(NotchBrand.quitMenuTitle, "Quit NotchApple", "quit menu title")
        expectEqual(NotchBrand.bundleIdentifier, "io.notchapple.NotchApple", "bundle id")
        expectEqual(NotchBrand.applicationSupportDirectoryName, "NotchApple", "new support directory")
        expectEqual(NotchBrand.legacyApplicationSupportDirectoryName, "MacNotch", "legacy support directory")
        expect(NotchBrand.affiliationDisclaimer.contains("not affiliated with Apple"), "affiliation disclaimer is explicit")
    }

    test("AppCore reads public brand values") {
        expectEqual(AppCore.displayName, "NotchApple", "display name")
        expectEqual(AppCore.bundleID, "io.notchapple.NotchApple", "bundle id")
    }
}
```

Append the call in `Sources/MacNotchTests/main.swift` after `macNotchAppTests()`:

```swift
notchBrandTests()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift run MacNotchTests`

Expected: FAIL with errors that `NotchBrand` and `AppCore.displayName` are not defined.

- [ ] **Step 3: Add brand constants**

Create `Sources/MacNotchKit/App/NotchBrand.swift`:

```swift
import Foundation

public enum NotchBrand {
    public static let productName = "NotchApple"
    public static let settingsTitle = "NotchApple Settings"
    public static let quitMenuTitle = "Quit NotchApple"
    public static let bundleIdentifier = "io.notchapple.NotchApple"
    public static let applicationSupportDirectoryName = "NotchApple"
    public static let legacyApplicationSupportDirectoryName = "MacNotch"
    public static let userAgent = "NotchApple/1.0"
    public static let affiliationDisclaimer = "NotchApple is not affiliated with Apple Inc."
}
```

Modify `Sources/MacNotchKit/App/AppCore.swift`:

```swift
import Foundation

public enum AppCore {
    public static let version = "0.1.0"
    public static let displayName = NotchBrand.productName
    public static let bundleID = NotchBrand.bundleIdentifier
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift run MacNotchTests`

Expected: PASS for the new brand tests and existing suite.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacNotchKit/App/NotchBrand.swift Sources/MacNotchKit/App/AppCore.swift Sources/MacNotchTests/NotchBrandTests.swift Sources/MacNotchTests/main.swift
git commit -m "feat: add NotchApple brand constants"
```

---

### Task 2: Public Rename Across App Surfaces and Packaging

**Files:**
- Modify: `Sources/MacNotchKit/App/MenuBarController.swift`
- Modify: `Sources/MacNotchKit/App/SettingsWindowController.swift`
- Modify: `Sources/MacNotchKit/UI/DashboardLayoutView.swift`
- Modify: `Sources/MacNotchKit/Modules/Customize/CustomizeViews.swift`
- Modify: `Sources/MacNotchKit/Modules/Media/LyricsFetcher.swift`
- Modify: `Sources/MacNotchKit/Modules/Stocks/StocksModule.swift`
- Modify: `Scripts/package-app.sh`
- Modify: `Makefile`
- Modify: `README.md`

**Interfaces:**
- Consumes: `NotchBrand` from Task 1.
- Produces: public app copy and package metadata that uses NotchApple.

- [ ] **Step 1: Write the packaging identity checks**

Add a shell check section to the manual verification notes in `README.md` under Build & run:

````markdown
## Public identity checks

Before a public build:

```bash
rg -n '"MacNotch"|>MacNotch<|Quit MacNotch|MacNotch Settings|com.macnotch.app' \
  Sources Scripts Makefile README.md website/index.html
```

Expected: no public-facing launch copy remains except legacy migration code, internal target names, and historical documentation that explicitly says it is legacy.
````

- [ ] **Step 2: Run the check to verify it fails before rename**

Run:

```bash
rg -n '"MacNotch"|>MacNotch<|Quit MacNotch|MacNotch Settings|com.macnotch.app' Sources Scripts Makefile README.md
```

Expected: matches in menu, settings, dashboard, customize, scripts, and docs.

- [ ] **Step 3: Rename visible app copy**

Apply these code changes:

`Sources/MacNotchKit/App/MenuBarController.swift`:

```swift
item.button?.image = NSImage(
    systemSymbolName: "rectangle.topthird.inset.filled",
    accessibilityDescription: NotchBrand.productName
)
menu.addItem(withTitle: "Open NotchApple", action: #selector(toggleNotch), keyEquivalent: "")
    .target = self
menu.addItem(withTitle: "Open Settings…", action: #selector(openSettings), keyEquivalent: ",")
    .target = self
menu.addItem(.separator())
menu.addItem(withTitle: NotchBrand.quitMenuTitle, action: #selector(quit), keyEquivalent: "q")
    .target = self
```

`Sources/MacNotchKit/App/SettingsWindowController.swift`:

```swift
window.title = NotchBrand.settingsTitle
```

`Sources/MacNotchKit/UI/DashboardLayoutView.swift`:

```swift
Text(NotchBrand.productName)
```

`Sources/MacNotchKit/Modules/Customize/CustomizeViews.swift`:

```swift
TileHeader(title: "Design Studio", systemImage: "slider.horizontal.3")
```

`Sources/MacNotchKit/Modules/Media/LyricsFetcher.swift` and `Sources/MacNotchKit/Modules/Stocks/StocksModule.swift`:

```swift
request.setValue(NotchBrand.userAgent, forHTTPHeaderField: "User-Agent")
```

- [ ] **Step 4: Rename package outputs**

Modify `Scripts/package-app.sh` to use NotchApple outputs:

```bash
APP_NAME="NotchApple"
APP="$ROOT/build/${APP_NAME}.app"
DMG="$ROOT/build/${APP_NAME}.dmg"
BIN_SRC="$ROOT/.build/release/MacNotch"
VERSION="${1:-0.1.0}"
```

Use the existing `MacNotch` executable target for the build artifact, but copy it into the public app as `NotchApple`:

```bash
cp "$BIN_SRC" "$APP/Contents/MacOS/NotchApple"
```

Set Info.plist public values:

```xml
<key>CFBundleName</key><string>NotchApple</string>
<key>CFBundleDisplayName</key><string>NotchApple</string>
<key>CFBundleIdentifier</key><string>io.notchapple.NotchApple</string>
<key>CFBundleExecutable</key><string>NotchApple</string>
<key>NSCalendarsUsageDescription</key>
<string>NotchApple shows your upcoming events in the notch.</string>
<key>NSAppleEventsUsageDescription</key>
<string>NotchApple controls Music and Spotify playback from the notch.</string>
```

Stage the DMG with public naming:

```bash
cp -r "$APP" "$STAGING/NotchApple.app"
hdiutil create \
  -volname "NotchApple" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$DMG" > /dev/null
```

Modify `Makefile`:

```make
run: package
	-pkill -x NotchApple; sleep 0.4
	open ./build/NotchApple.app
```

- [ ] **Step 5: Run tests and identity checks**

Run:

```bash
swift run MacNotchTests
rg -n '"MacNotch"|>MacNotch<|Quit MacNotch|MacNotch Settings|com.macnotch.app' Sources Scripts Makefile README.md
```

Expected: tests pass. Search output only includes internal target names, explicit legacy migration references, or historical README text that says legacy.

- [ ] **Step 6: Commit**

```bash
git add Sources/MacNotchKit/App/MenuBarController.swift Sources/MacNotchKit/App/SettingsWindowController.swift Sources/MacNotchKit/UI/DashboardLayoutView.swift Sources/MacNotchKit/Modules/Customize/CustomizeViews.swift Sources/MacNotchKit/Modules/Media/LyricsFetcher.swift Sources/MacNotchKit/Modules/Stocks/StocksModule.swift Scripts/package-app.sh Makefile README.md
git commit -m "feat: rename public surfaces to NotchApple"
```

---

### Task 3: Application Support Migration

**Files:**
- Create: `Sources/MacNotchKit/App/AppDataLocations.swift`
- Create: `Sources/MacNotchKit/App/AppDataMigrator.swift`
- Create: `Sources/MacNotchTests/AppDataMigratorTests.swift`
- Modify: `Sources/MacNotchKit/App/SettingsStore.swift`
- Modify: `Sources/MacNotchKit/Modules/Shelf/ShelfStore.swift`
- Modify: `Sources/MacNotchKit/Modules/Code/CodeProjectStore.swift`
- Modify: `Sources/MacNotchKit/Modules/Launcher/LauncherStore.swift`
- Modify: `Sources/MacNotchKit/Modules/Reminders/RemindersStore.swift`
- Modify: `Sources/MacNotchKit/Modules/Clipboard/ClipboardStore.swift`
- Modify: `Sources/MacNotchKit/Modules/ScreenTime/ScreenTimeModule.swift`
- Modify: `Sources/MacNotchKit/App/AppDelegate.swift`
- Modify: `Sources/MacNotchTests/main.swift`

**Interfaces:**
- Produces: `AppDataLocations`, `AppDataMigrator.migrateIfNeeded(fileManager:)`.
- Consumes: `NotchBrand.applicationSupportDirectoryName`, `NotchBrand.legacyApplicationSupportDirectoryName`.

- [ ] **Step 1: Write failing migration tests**

Create `Sources/MacNotchTests/AppDataMigratorTests.swift`:

```swift
import Foundation
import MacNotchKit

func appDataMigratorTests() {
    func root() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    test("AppDataLocations derives legacy and current support directories") {
        let base = root()
        let locations = AppDataLocations(baseApplicationSupportURL: base)
        expectEqual(locations.currentDirectory.lastPathComponent, "NotchApple", "current directory")
        expectEqual(locations.legacyDirectory.lastPathComponent, "MacNotch", "legacy directory")
        expectEqual(locations.settingsURL.lastPathComponent, "settings.json", "settings path")
    }

    test("migration copies legacy data once and writes marker") {
        let base = root()
        let locations = AppDataLocations(baseApplicationSupportURL: base)
        try! FileManager.default.createDirectory(at: locations.legacyDirectory, withIntermediateDirectories: true)
        try! Data("legacy".utf8).write(to: locations.legacyDirectory.appendingPathComponent("settings.json"))

        let migrator = AppDataMigrator(locations: locations)
        expect(migrator.migrateIfNeeded(), "first migration succeeds")
        expectEqual(
            try! String(contentsOf: locations.currentDirectory.appendingPathComponent("settings.json")),
            "legacy",
            "legacy settings copied"
        )
        expect(FileManager.default.fileExists(atPath: locations.migrationMarkerURL.path), "marker written")

        try! Data("new".utf8).write(to: locations.currentDirectory.appendingPathComponent("settings.json"))
        expect(migrator.migrateIfNeeded(), "second migration is a no-op success")
        expectEqual(
            try! String(contentsOf: locations.currentDirectory.appendingPathComponent("settings.json")),
            "new",
            "current settings not overwritten"
        )
    }
}
```

Append in `Sources/MacNotchTests/main.swift` after `settingsStoreTests()`:

```swift
appDataMigratorTests()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift run MacNotchTests`

Expected: FAIL because `AppDataLocations` and `AppDataMigrator` are missing.

- [ ] **Step 3: Add data location and migration types**

Create `Sources/MacNotchKit/App/AppDataLocations.swift`:

```swift
import Foundation

public struct AppDataLocations: Sendable {
    public let baseApplicationSupportURL: URL

    public init(baseApplicationSupportURL: URL = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
    )[0]) {
        self.baseApplicationSupportURL = baseApplicationSupportURL
    }

    public var currentDirectory: URL {
        baseApplicationSupportURL.appendingPathComponent(NotchBrand.applicationSupportDirectoryName, isDirectory: true)
    }

    public var legacyDirectory: URL {
        baseApplicationSupportURL.appendingPathComponent(NotchBrand.legacyApplicationSupportDirectoryName, isDirectory: true)
    }

    public var migrationMarkerURL: URL {
        currentDirectory.appendingPathComponent(".macnotch-migrated")
    }

    public var settingsURL: URL {
        currentDirectory.appendingPathComponent("settings.json")
    }
}
```

Create `Sources/MacNotchKit/App/AppDataMigrator.swift`:

```swift
import Foundation

public struct AppDataMigrator {
    private let locations: AppDataLocations
    private let fileManager: FileManager

    public init(locations: AppDataLocations = AppDataLocations(),
                fileManager: FileManager = .default) {
        self.locations = locations
        self.fileManager = fileManager
    }

    @discardableResult
    public func migrateIfNeeded() -> Bool {
        if fileManager.fileExists(atPath: locations.migrationMarkerURL.path) {
            return true
        }
        guard fileManager.fileExists(atPath: locations.legacyDirectory.path) else {
            return writeMarker()
        }

        do {
            try fileManager.createDirectory(at: locations.currentDirectory, withIntermediateDirectories: true)
            let legacyContents = try fileManager.contentsOfDirectory(
                at: locations.legacyDirectory,
                includingPropertiesForKeys: nil
            )
            for source in legacyContents {
                let destination = locations.currentDirectory.appendingPathComponent(source.lastPathComponent)
                if !fileManager.fileExists(atPath: destination.path) {
                    try fileManager.copyItem(at: source, to: destination)
                }
            }
            return writeMarker()
        } catch {
            NSLog("NotchApple migration failed: \(error.localizedDescription)")
            return false
        }
    }

    private func writeMarker() -> Bool {
        do {
            try fileManager.createDirectory(at: locations.currentDirectory, withIntermediateDirectories: true)
            try Data("migrated".utf8).write(to: locations.migrationMarkerURL, options: .atomic)
            return true
        } catch {
            NSLog("NotchApple migration marker failed: \(error.localizedDescription)")
            return false
        }
    }
}
```

- [ ] **Step 4: Point stores at NotchApple support paths**

Modify `SettingsStore.defaultURL()`:

```swift
public static func defaultURL() -> URL {
    AppDataLocations().settingsURL
}
```

For each store that currently appends `"MacNotch/<file>.json"`, replace the path root with `AppDataLocations().currentDirectory`. Example for `ShelfStore`:

```swift
let dir = AppDataLocations().currentDirectory
return dir.appendingPathComponent("shelf.json")
```

Use the existing file names:

- `shelf.json`
- `code-projects.json`
- `launcher.json`
- `reminders.json`
- clipboard store file name already in `ClipboardStore.swift`
- screen-time file name already in `ScreenTimeModule.swift`

- [ ] **Step 5: Run migrator before settings load**

Modify `Sources/MacNotchKit/App/AppDelegate.swift`:

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    _ = AppDataMigrator().migrateIfNeeded()
    settings.load()
    registerModules()
    ...
}
```

- [ ] **Step 6: Run tests**

Run: `swift run MacNotchTests`

Expected: PASS, including app data migration tests and existing store tests.

- [ ] **Step 7: Commit**

```bash
git add Sources/MacNotchKit/App/AppDataLocations.swift Sources/MacNotchKit/App/AppDataMigrator.swift Sources/MacNotchKit/App/SettingsStore.swift Sources/MacNotchKit/App/AppDelegate.swift Sources/MacNotchKit/Modules/Shelf/ShelfStore.swift Sources/MacNotchKit/Modules/Code/CodeProjectStore.swift Sources/MacNotchKit/Modules/Launcher/LauncherStore.swift Sources/MacNotchKit/Modules/Reminders/RemindersStore.swift Sources/MacNotchKit/Modules/Clipboard/ClipboardStore.swift Sources/MacNotchKit/Modules/ScreenTime/ScreenTimeModule.swift Sources/MacNotchTests/AppDataMigratorTests.swift Sources/MacNotchTests/main.swift
git commit -m "feat: migrate app data to NotchApple storage"
```

---

### Task 4: Appearance Model and Settings Persistence

**Files:**
- Create: `Sources/MacNotchKit/App/NotchAppearance.swift`
- Create: `Sources/MacNotchTests/NotchAppearanceTests.swift`
- Modify: `Sources/MacNotchKit/App/AppSettings.swift`
- Modify: `Sources/MacNotchTests/SettingsStoreTests.swift`
- Modify: `Sources/MacNotchTests/main.swift`

**Interfaces:**
- Produces: `NotchAppearance`, `AppearancePreset`, `AccentColorChoice`, `GlassIntensity`, `PanelDensity`, `CornerStyle`, `MotionStyle`, `DashboardLayoutPreference`, `MenuBarIconStyle`.
- Consumes: `AppSettings` persistence.

- [ ] **Step 1: Write failing appearance tests**

Create `Sources/MacNotchTests/NotchAppearanceTests.swift`:

```swift
import Foundation
import MacNotchKit

func notchAppearanceTests() {
    test("default appearance is Studio Glass") {
        let appearance = NotchAppearance.defaults
        expectEqual(appearance.preset, .studioGlass, "default preset")
        expectEqual(appearance.motionStyle, .expressive, "default motion")
        expectEqual(appearance.panelDensity, .comfortable, "default density")
    }

    test("built-in presets expose launch set in order") {
        expectEqual(
            AppearancePreset.launchPresets,
            [.studioGlass, .minimalGraphite, .aurora, .terminal],
            "launch presets"
        )
    }

    test("appearance round-trips through AppSettings") {
        var settings = AppSettings.defaults
        settings.appearance = NotchAppearance(
            preset: .terminal,
            accentColor: .green,
            glassIntensity: .vivid,
            panelDensity: .compact,
            cornerStyle: .precise,
            motionStyle: .calm,
            dashboardLayout: .priority,
            menuBarIconStyle: .monochrome
        )
        let data = try! JSONEncoder().encode(settings)
        let decoded = try! JSONDecoder().decode(AppSettings.self, from: data)
        expectEqual(decoded.appearance.preset, .terminal, "preset persists")
        expectEqual(decoded.appearance.motionStyle, .calm, "motion persists")
    }

    test("legacy settings without appearance use defaults") {
        let legacyJSON = """
        {"modules":[{"id":"media","isEnabled":true}],"launchAtLogin":false,"defaultExpansionMode":"dashboard"}
        """
        let decoded = try! JSONDecoder().decode(AppSettings.self, from: Data(legacyJSON.utf8))
        expectEqual(decoded.appearance, .defaults, "legacy appearance fallback")
    }
}
```

Append in `Sources/MacNotchTests/main.swift` after `settingsLogicTests()`:

```swift
notchAppearanceTests()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift run MacNotchTests`

Expected: FAIL because appearance types and `AppSettings.appearance` are missing.

- [ ] **Step 3: Add appearance model**

Create `Sources/MacNotchKit/App/NotchAppearance.swift`:

```swift
import Foundation

public enum AppearancePreset: String, Codable, CaseIterable, Sendable {
    case studioGlass
    case minimalGraphite
    case aurora
    case terminal
    case paper

    public static let launchPresets: [AppearancePreset] = [
        .studioGlass, .minimalGraphite, .aurora, .terminal
    ]
}

public enum AccentColorChoice: String, Codable, CaseIterable, Sendable {
    case cyan, blue, purple, green, amber, red
}

public enum GlassIntensity: String, Codable, CaseIterable, Sendable {
    case subtle, balanced, vivid
}

public enum PanelDensity: String, Codable, CaseIterable, Sendable {
    case compact, comfortable, spacious
}

public enum CornerStyle: String, Codable, CaseIterable, Sendable {
    case precise, soft, pill
}

public enum MotionStyle: String, Codable, CaseIterable, Sendable {
    case expressive, calm, reduced
}

public enum DashboardLayoutPreference: String, Codable, CaseIterable, Sendable {
    case pagedTiles, priority, fullPageFocus
}

public enum MenuBarIconStyle: String, Codable, CaseIterable, Sendable {
    case monochrome, accent, hiddenWhenPossible
}

public struct NotchAppearance: Codable, Equatable, Sendable {
    public var preset: AppearancePreset
    public var accentColor: AccentColorChoice
    public var glassIntensity: GlassIntensity
    public var panelDensity: PanelDensity
    public var cornerStyle: CornerStyle
    public var motionStyle: MotionStyle
    public var dashboardLayout: DashboardLayoutPreference
    public var menuBarIconStyle: MenuBarIconStyle

    public init(preset: AppearancePreset,
                accentColor: AccentColorChoice,
                glassIntensity: GlassIntensity,
                panelDensity: PanelDensity,
                cornerStyle: CornerStyle,
                motionStyle: MotionStyle,
                dashboardLayout: DashboardLayoutPreference,
                menuBarIconStyle: MenuBarIconStyle) {
        self.preset = preset
        self.accentColor = accentColor
        self.glassIntensity = glassIntensity
        self.panelDensity = panelDensity
        self.cornerStyle = cornerStyle
        self.motionStyle = motionStyle
        self.dashboardLayout = dashboardLayout
        self.menuBarIconStyle = menuBarIconStyle
    }

    public static let defaults = NotchAppearance(
        preset: .studioGlass,
        accentColor: .cyan,
        glassIntensity: .balanced,
        panelDensity: .comfortable,
        cornerStyle: .soft,
        motionStyle: .expressive,
        dashboardLayout: .pagedTiles,
        menuBarIconStyle: .monochrome
    )
}
```

- [ ] **Step 4: Persist appearance in settings**

Modify `Sources/MacNotchKit/App/AppSettings.swift`:

```swift
public var appearance: NotchAppearance
public var activeWorkspaceProfileID: String?
```

Update initializer:

```swift
public init(modules: [ModuleSetting],
            launchAtLogin: Bool,
            defaultExpansionMode: ExpansionMode = .dashboard,
            appearance: NotchAppearance = .defaults,
            activeWorkspaceProfileID: String? = nil) {
    self.modules = modules
    self.launchAtLogin = launchAtLogin
    self.defaultExpansionMode = defaultExpansionMode
    self.appearance = appearance
    self.activeWorkspaceProfileID = activeWorkspaceProfileID
}
```

Update coding keys:

```swift
case modules, launchAtLogin, defaultExpansionMode, appearance, activeWorkspaceProfileID
```

Update custom decode:

```swift
appearance = try container.decodeIfPresent(NotchAppearance.self, forKey: .appearance) ?? .defaults
activeWorkspaceProfileID = try container.decodeIfPresent(String.self, forKey: .activeWorkspaceProfileID)
```

Update `mergingPersisted` return:

```swift
return AppSettings(modules: modules,
                   launchAtLogin: persisted.launchAtLogin,
                   defaultExpansionMode: persisted.defaultExpansionMode,
                   appearance: persisted.appearance,
                   activeWorkspaceProfileID: persisted.activeWorkspaceProfileID)
```

- [ ] **Step 5: Run tests**

Run: `swift run MacNotchTests`

Expected: PASS, including legacy settings tests.

- [ ] **Step 6: Commit**

```bash
git add Sources/MacNotchKit/App/NotchAppearance.swift Sources/MacNotchKit/App/AppSettings.swift Sources/MacNotchTests/NotchAppearanceTests.swift Sources/MacNotchTests/SettingsStoreTests.swift Sources/MacNotchTests/main.swift
git commit -m "feat: persist NotchApple appearance settings"
```

---

### Task 5: Theme Token Engine

**Files:**
- Create: `Sources/MacNotchKit/UI/NotchTheme.swift`
- Modify: `Sources/MacNotchKit/UI/DashboardTileChrome.swift`
- Modify: `Sources/MacNotchKit/UI/NotchRootView.swift`
- Modify: `Sources/MacNotchKit/UI/DashboardLayoutView.swift`
- Modify: `Sources/MacNotchKit/UI/WideBarLayoutView.swift`
- Modify: `Sources/MacNotchKit/App/AppDelegate.swift`
- Modify: `Sources/MacNotchKit/App/SettingsStore.swift`
- Create: `Sources/MacNotchTests/NotchThemeTests.swift`
- Modify: `Sources/MacNotchTests/main.swift`

**Interfaces:**
- Produces: `NotchTheme.tokens(for:colorScheme:reduceMotion:) -> NotchThemeTokens`.
- Consumes: `NotchAppearance` from Task 4.

- [ ] **Step 1: Write failing theme token tests**

Create `Sources/MacNotchTests/NotchThemeTests.swift`:

```swift
import MacNotchKit

func notchThemeTests() {
    test("theme tokens derive accent from appearance") {
        var appearance = NotchAppearance.defaults
        appearance.accentColor = .green
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: false)
        expectEqual(tokens.accentName, "green", "accent token name")
    }

    test("reduced motion overrides expressive motion") {
        var appearance = NotchAppearance.defaults
        appearance.motionStyle = .expressive
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: true)
        expectEqual(tokens.motionStyle, .reduced, "system reduced motion wins")
    }

    test("terminal preset uses precise corners") {
        var appearance = NotchAppearance.defaults
        appearance.preset = .terminal
        let tokens = NotchTheme.tokens(for: appearance, reduceMotion: false)
        expectEqual(tokens.cornerRadius, 6, "terminal corners")
    }
}
```

Append in `Sources/MacNotchTests/main.swift` after `notchAppearanceTests()`:

```swift
notchThemeTests()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift run MacNotchTests`

Expected: FAIL because `NotchTheme.tokens` and `NotchThemeTokens` are missing.

- [ ] **Step 3: Move theme constants to a real theme file**

Create `Sources/MacNotchKit/UI/NotchTheme.swift` and move the current `NotchTheme` enum out of `DashboardTileChrome.swift`. Extend it:

```swift
import SwiftUI

public struct NotchThemeTokens: Equatable, Sendable {
    public var accentName: String
    public var cornerRadius: CGFloat
    public var tileCornerRadius: CGFloat
    public var glassOpacity: Double
    public var strokeOpacity: Double
    public var motionStyle: MotionStyle
}

enum NotchTheme {
    static let tileCornerRadius: CGFloat = 8
    static let tileFill = Color.white.opacity(0.075)
    static let tileStroke = Color.white.opacity(0.10)
    static let hairline = Color.white.opacity(0.10)
    static let accent = Color(red: 0.36, green: 0.78, blue: 1)

    static func tokens(for appearance: NotchAppearance, reduceMotion: Bool) -> NotchThemeTokens {
        let resolvedMotion: MotionStyle = reduceMotion ? .reduced : appearance.motionStyle
        let presetCorner: CGFloat = appearance.preset == .terminal ? 6 : 8
        return NotchThemeTokens(
            accentName: appearance.accentColor.rawValue,
            cornerRadius: presetCorner,
            tileCornerRadius: presetCorner,
            glassOpacity: appearance.glassIntensity == .vivid ? 0.78 : 0.62,
            strokeOpacity: appearance.glassIntensity == .subtle ? 0.08 : 0.14,
            motionStyle: resolvedMotion
        )
    }

    static func tileFillGradient(hovered: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(hovered ? 0.10 : 0.075),
                Color.white.opacity(hovered ? 0.08 : 0.060)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func tileStrokeGradient(hovered: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(hovered ? 0.18 : 0.10),
                Color.white.opacity(hovered ? 0.10 : 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
```

- [ ] **Step 4: Thread appearance into root UI**

Add `@Published public var appearance = NotchAppearance.defaults` to `NotchWindowModel`.

When `NotchWindow.reload()` runs, set:

```swift
model.appearance = settings.settings.appearance
```

Also set it during initialization after `sync()`:

```swift
model.appearance = settings.settings.appearance
```

Use `model.appearance` in `NotchRootView`, `DashboardLayoutView`, and `WideBarLayoutView` where theme tokens are needed. Keep existing visual constants as fallback until each surface is fully themed.

- [ ] **Step 5: Run tests**

Run: `swift run MacNotchTests`

Expected: PASS, including theme token tests.

- [ ] **Step 6: Manual visual check**

Run: `make run`

Expected: app launches as NotchApple, the current theme still resembles the existing polished dark glass, and no module layout regresses.

- [ ] **Step 7: Commit**

```bash
git add Sources/MacNotchKit/UI/NotchTheme.swift Sources/MacNotchKit/UI/DashboardTileChrome.swift Sources/MacNotchKit/UI/NotchRootView.swift Sources/MacNotchKit/UI/DashboardLayoutView.swift Sources/MacNotchKit/UI/WideBarLayoutView.swift Sources/MacNotchKit/App/AppDelegate.swift Sources/MacNotchKit/App/SettingsStore.swift Sources/MacNotchTests/NotchThemeTests.swift Sources/MacNotchTests/main.swift
git commit -m "feat: add appearance-driven theme tokens"
```

---

### Task 6: Shared UI Primitives and Module State Views

**Files:**
- Create: `Sources/MacNotchKit/UI/NotchControls.swift`
- Create: `Sources/MacNotchKit/UI/ModuleStateViews.swift`
- Modify: `Sources/MacNotchKit/UI/DashboardLayoutView.swift`
- Modify: `Sources/MacNotchKit/UI/NotchRootView.swift`
- Modify: `Sources/MacNotchKit/Modules/QuickToggles/QuickTogglesViews.swift`
- Modify: `Sources/MacNotchKit/Modules/Timers/TimersViews.swift`
- Modify: `Sources/MacNotchKit/Modules/Shelf/ShelfViews.swift`

**Interfaces:**
- Produces: `NotchIconButton`, `NotchSegmentedControl`, `NotchFocusRing`, `ModuleEmptyStateView`, `ModulePermissionStateView`, `ModuleLoadingStateView`, `ModuleErrorStateView`.
- Consumes: `NotchTheme` and `NotchAppearance`.

- [ ] **Step 1: Add shared controls**

Create `Sources/MacNotchKit/UI/NotchControls.swift`:

```swift
import SwiftUI

struct NotchIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}

struct NotchSegmentedControl<Option: Hashable, Label: View>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> Label

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    label(option)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selection == option ? Color.white.opacity(0.14) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct NotchFocusRing: ViewModifier {
    let isFocused: Bool

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: NotchTheme.tileCornerRadius)
                .strokeBorder(isFocused ? NotchTheme.accent.opacity(0.85) : .clear, lineWidth: 1.5)
        )
    }
}

extension View {
    func notchFocusRing(isFocused: Bool) -> some View {
        modifier(NotchFocusRing(isFocused: isFocused))
    }
}
```

- [ ] **Step 2: Add shared module states**

Create `Sources/MacNotchKit/UI/ModuleStateViews.swift`:

```swift
import SwiftUI

struct ModuleEmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(NotchTheme.accent.opacity(0.85))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.90))
            Text(message)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct ModuleLoadingStateView: View {
    let message: String

    var body: some View {
        ProgressView(message)
            .progressViewStyle(.circular)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(message)
    }
}

struct ModulePermissionStateView: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            ModuleEmptyStateView(title: title, message: message, systemImage: "lock.shield")
            Button(actionTitle, action: action)
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 7).fill(NotchTheme.accent.opacity(0.18)))
        }
    }
}

struct ModuleErrorStateView: View {
    let title: String
    let message: String
    let retry: (() -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            ModuleEmptyStateView(title: title, message: message, systemImage: "exclamationmark.triangle")
            if let retry {
                Button("Retry", action: retry)
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .semibold))
            }
        }
    }
}
```

- [ ] **Step 3: Replace the smallest repeated controls first**

In `DashboardLayoutView`, replace arrow buttons and lock button with `NotchIconButton` while preserving existing actions:

```swift
NotchIconButton(
    systemName: systemName,
    accessibilityLabel: systemName == "chevron.left" ? "Previous dashboard page" : "Next dashboard page",
    action: action
)
.disabled(!enabled)
```

In `NotchRootView`, replace compact footer lock and dashboard buttons with accessible labels:

```swift
.accessibilityLabel(model.isPinned ? "Unpin notch panel" : "Pin notch panel")
```

- [ ] **Step 4: Run tests and manual accessibility smoke check**

Run: `swift run MacNotchTests`

Expected: PASS.

Manual:

1. Run `make run`.
2. Open the dashboard.
3. Confirm arrow buttons, pin button, and compact dashboard button still work.
4. Hover each icon button and confirm help text appears.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacNotchKit/UI/NotchControls.swift Sources/MacNotchKit/UI/ModuleStateViews.swift Sources/MacNotchKit/UI/DashboardLayoutView.swift Sources/MacNotchKit/UI/NotchRootView.swift Sources/MacNotchKit/Modules/QuickToggles/QuickTogglesViews.swift Sources/MacNotchKit/Modules/Timers/TimersViews.swift Sources/MacNotchKit/Modules/Shelf/ShelfViews.swift
git commit -m "feat: add shared NotchApple UI primitives"
```

---

### Task 7: Settings Window Reorganization and Design Tab

**Files:**
- Create: `Sources/MacNotchKit/App/SettingsSections.swift`
- Create: `Sources/MacNotchKit/App/DesignSettingsView.swift`
- Modify: `Sources/MacNotchKit/App/SettingsView.swift`
- Modify: `Sources/MacNotchKit/App/SettingsWindowController.swift`
- Modify: `Sources/MacNotchTests/SettingsLogicTests.swift`

**Interfaces:**
- Consumes: `NotchAppearance`, `AppSettings`, `SettingsLogic`.
- Produces: tabbed settings sections: General, Modules, Design, Privacy, Shortcuts, About.

- [ ] **Step 1: Add settings section model**

Create `Sources/MacNotchKit/App/SettingsSections.swift`:

```swift
import Foundation

enum SettingsSection: String, CaseIterable, Identifiable {
    case general = "General"
    case modules = "Modules"
    case design = "Design"
    case privacy = "Privacy"
    case shortcuts = "Shortcuts"
    case about = "About"

    var id: String { rawValue }
}
```

- [ ] **Step 2: Add pure appearance mutation helpers**

Modify `SettingsLogic.swift`:

```swift
public static func setAppearancePreset(_ settings: inout AppSettings, preset: AppearancePreset) {
    settings.appearance.preset = preset
}

public static func setMotionStyle(_ settings: inout AppSettings, motionStyle: MotionStyle) {
    settings.appearance.motionStyle = motionStyle
}

public static func setPanelDensity(_ settings: inout AppSettings, density: PanelDensity) {
    settings.appearance.panelDensity = density
}
```

Add tests in `SettingsLogicTests.swift`:

```swift
test("appearance mutations update settings") {
    var settings = AppSettings.defaults
    SettingsLogic.setAppearancePreset(&settings, preset: .terminal)
    SettingsLogic.setMotionStyle(&settings, motionStyle: .calm)
    SettingsLogic.setPanelDensity(&settings, density: .compact)
    expectEqual(settings.appearance.preset, .terminal, "preset changed")
    expectEqual(settings.appearance.motionStyle, .calm, "motion changed")
    expectEqual(settings.appearance.panelDensity, .compact, "density changed")
}
```

- [ ] **Step 3: Run test to verify helper behavior**

Run: `swift run MacNotchTests`

Expected: PASS.

- [ ] **Step 4: Add Design tab view**

Create `Sources/MacNotchKit/App/DesignSettingsView.swift`:

```swift
import SwiftUI

struct DesignSettingsView: View {
    @Binding var settings: AppSettings
    let onChange: (AppSettings) -> Void

    var body: some View {
        Form {
            Section("Preset") {
                Picker("Theme", selection: Binding(
                    get: { settings.appearance.preset },
                    set: { preset in
                        settings.appearance.preset = preset
                        onChange(settings)
                    }
                )) {
                    ForEach(AppearancePreset.launchPresets, id: \.self) { preset in
                        Text(label(for: preset)).tag(preset)
                    }
                }
            }

            Section("Feel") {
                Picker("Density", selection: Binding(
                    get: { settings.appearance.panelDensity },
                    set: { density in
                        settings.appearance.panelDensity = density
                        onChange(settings)
                    }
                )) {
                    Text("Compact").tag(PanelDensity.compact)
                    Text("Comfortable").tag(PanelDensity.comfortable)
                    Text("Spacious").tag(PanelDensity.spacious)
                }

                Picker("Motion", selection: Binding(
                    get: { settings.appearance.motionStyle },
                    set: { motion in
                        settings.appearance.motionStyle = motion
                        onChange(settings)
                    }
                )) {
                    Text("Expressive").tag(MotionStyle.expressive)
                    Text("Calm").tag(MotionStyle.calm)
                    Text("Reduced").tag(MotionStyle.reduced)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func label(for preset: AppearancePreset) -> String {
        switch preset {
        case .studioGlass: return "Studio Glass"
        case .minimalGraphite: return "Minimal Graphite"
        case .aurora: return "Aurora"
        case .terminal: return "Terminal"
        case .paper: return "Paper"
        }
    }
}
```

- [ ] **Step 5: Rebuild SettingsView as tabbed product settings**

Modify `SettingsView` to use a sidebar `NavigationSplitView` or `TabView`. Minimum acceptable structure:

```swift
@State private var selectedSection: SettingsSection = .general
```

Render:

```swift
HStack(spacing: 0) {
    List(SettingsSection.allCases, selection: $selectedSection) { section in
        Text(section.rawValue).tag(section)
    }
    .frame(width: 150)

    Group {
        switch selectedSection {
        case .general:
            generalSection
        case .modules:
            modulesSection
        case .design:
            DesignSettingsView(settings: $settings, onChange: onChange)
        case .privacy:
            privacySection
        case .shortcuts:
            shortcutsSection
        case .about:
            aboutSection
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
.frame(width: 720, height: 520)
```

Use existing module toggles in `modulesSection`, existing launch/default expansion controls in `generalSection`, and add plain text for Privacy/About:

```swift
Text(NotchBrand.affiliationDisclaimer)
Text("NotchApple stores settings locally in Application Support and only asks for permissions when a module needs them.")
```

Modify `SettingsWindowController` window size to `720x520`.

- [ ] **Step 6: Run tests and manual settings check**

Run: `swift run MacNotchTests`

Expected: PASS.

Manual:

1. Run `make run`.
2. Open Settings from menu bar.
3. Confirm General, Modules, Design, Privacy, Shortcuts, and About are visible.
4. Change a preset and confirm it persists after closing and reopening Settings.

- [ ] **Step 7: Commit**

```bash
git add Sources/MacNotchKit/App/SettingsSections.swift Sources/MacNotchKit/App/DesignSettingsView.swift Sources/MacNotchKit/App/SettingsView.swift Sources/MacNotchKit/App/SettingsWindowController.swift Sources/MacNotchKit/App/SettingsLogic.swift Sources/MacNotchTests/SettingsLogicTests.swift
git commit -m "feat: add NotchApple design settings"
```

---

### Task 8: Customize Tile as In-Notch Design Studio

**Files:**
- Modify: `Sources/MacNotchKit/Modules/Customize/CustomizeModule.swift`
- Modify: `Sources/MacNotchKit/Modules/Customize/CustomizeViews.swift`
- Modify: `Sources/MacNotchKit/App/AppDelegate.swift`

**Interfaces:**
- Consumes: `NotchAppearance`, `SettingsLogic`, `NotchSegmentedControl`.
- Produces: fast in-notch Design Studio controls.

- [ ] **Step 1: Extend SettingsProxy with appearance-aware actions**

In `CustomizeModule.SettingsProxy`, add methods:

```swift
func update(_ mutate: (inout AppSettings) -> Void) {
    var next = settings
    mutate(&next)
    settings = next
    onChange(next)
}
```

- [ ] **Step 2: Replace tile content with Design Studio controls**

In `CustomizeDashboardTile`, keep module toggles but add preset and density controls above them:

```swift
TileHeader(title: "Design Studio", systemImage: "slider.horizontal.3")

Text("PRESET")
    .font(.system(size: 8, weight: .semibold))
    .foregroundStyle(.white.opacity(0.42))

HStack(spacing: 5) {
    ForEach(AppearancePreset.launchPresets, id: \.self) { preset in
        Button(shortLabel(for: preset)) {
            proxy.update { $0.appearance.preset = preset }
        }
        .buttonStyle(.plain)
        .font(.system(size: 8.5, weight: .semibold))
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(proxy.settings.appearance.preset == preset ? NotchTheme.accent.opacity(0.20) : .white.opacity(0.06))
        )
        .accessibilityLabel("Use \(label(for: preset)) theme")
    }
}
```

Add helper labels:

```swift
private func shortLabel(for preset: AppearancePreset) -> String {
    switch preset {
    case .studioGlass: return "Studio"
    case .minimalGraphite: return "Graphite"
    case .aurora: return "Aurora"
    case .terminal: return "Terminal"
    case .paper: return "Paper"
    }
}

private func label(for preset: AppearancePreset) -> String {
    switch preset {
    case .studioGlass: return "Studio Glass"
    case .minimalGraphite: return "Minimal Graphite"
    case .aurora: return "Aurora"
    case .terminal: return "Terminal"
    case .paper: return "Paper"
    }
}
```

- [ ] **Step 3: Keep launch and mode controls intact**

Use `proxy.update` for mode and launch bindings:

```swift
proxy.update { $0.defaultExpansionMode = mode }
```

and:

```swift
proxy.update { $0.launchAtLogin = isOn }
```

- [ ] **Step 4: Run tests and manual tile check**

Run: `swift run MacNotchTests`

Expected: PASS.

Manual:

1. Enable Customize in Settings.
2. Open dashboard.
3. Change presets from Customize tile.
4. Confirm the Settings Design tab reflects the selected preset.

- [ ] **Step 5: Commit**

```bash
git add Sources/MacNotchKit/Modules/Customize/CustomizeModule.swift Sources/MacNotchKit/Modules/Customize/CustomizeViews.swift Sources/MacNotchKit/App/AppDelegate.swift
git commit -m "feat: turn customize tile into design studio"
```

---

### Task 9: First-Run Onboarding and Trust Copy

**Files:**
- Create: `Sources/MacNotchKit/App/OnboardingState.swift`
- Create: `Sources/MacNotchKit/App/OnboardingView.swift`
- Create: `Sources/MacNotchKit/App/OnboardingWindowController.swift`
- Create: `Sources/MacNotchTests/OnboardingStateTests.swift`
- Modify: `Sources/MacNotchKit/App/AppSettings.swift`
- Modify: `Sources/MacNotchKit/App/AppDelegate.swift`
- Modify: `Sources/MacNotchTests/main.swift`

**Interfaces:**
- Produces: `OnboardingState`, `OnboardingWindowController.showIfNeeded(settings:onComplete:)`.
- Consumes: `NotchBrand`, `NotchAppearance`, `AppSettings`.

- [ ] **Step 1: Write failing onboarding state tests**

Create `Sources/MacNotchTests/OnboardingStateTests.swift`:

```swift
import MacNotchKit

func onboardingStateTests() {
    test("default onboarding is incomplete") {
        expectEqual(OnboardingState.defaults.hasCompletedFirstRun, false, "first run incomplete")
    }

    test("marking onboarding complete is codable") {
        let state = OnboardingState(hasCompletedFirstRun: true, completedVersion: "0.1.0")
        let data = try! JSONEncoder().encode(state)
        let decoded = try! JSONDecoder().decode(OnboardingState.self, from: data)
        expectEqual(decoded.hasCompletedFirstRun, true, "completion persists")
        expectEqual(decoded.completedVersion, "0.1.0", "version persists")
    }
}
```

Append in `Sources/MacNotchTests/main.swift`:

```swift
onboardingStateTests()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift run MacNotchTests`

Expected: FAIL because `OnboardingState` is missing.

- [ ] **Step 3: Add onboarding state**

Create `Sources/MacNotchKit/App/OnboardingState.swift`:

```swift
import Foundation

public struct OnboardingState: Codable, Equatable, Sendable {
    public var hasCompletedFirstRun: Bool
    public var completedVersion: String?

    public init(hasCompletedFirstRun: Bool, completedVersion: String?) {
        self.hasCompletedFirstRun = hasCompletedFirstRun
        self.completedVersion = completedVersion
    }

    public static let defaults = OnboardingState(
        hasCompletedFirstRun: false,
        completedVersion: nil
    )
}
```

Add to `AppSettings`:

```swift
public var onboarding: OnboardingState
```

Initialize and decode with fallback:

```swift
onboarding: OnboardingState = .defaults
```

and:

```swift
onboarding = try container.decodeIfPresent(OnboardingState.self, forKey: .onboarding) ?? .defaults
```

- [ ] **Step 4: Add onboarding window**

Create `Sources/MacNotchKit/App/OnboardingWindowController.swift`:

```swift
import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController {
    private var window: NSWindow?

    func showIfNeeded(settings: AppSettings, onComplete: @escaping (AppSettings) -> Void) {
        guard !settings.onboarding.hasCompletedFirstRun else { return }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to \(NotchBrand.productName)"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: OnboardingView(settings: settings, onComplete: onComplete))
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
```

Create `Sources/MacNotchKit/App/OnboardingView.swift`:

```swift
import SwiftUI

struct OnboardingView: View {
    @State private var settings: AppSettings
    let onComplete: (AppSettings) -> Void

    init(settings: AppSettings, onComplete: @escaping (AppSettings) -> Void) {
        _settings = State(initialValue: settings)
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Welcome to \(NotchBrand.productName)")
                .font(.system(size: 28, weight: .bold))
            Text("Your notch becomes a customizable command center for media, code, timers, reminders, files, and focused work.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                Text("Permissions are requested only when a module needs them.")
                Text("Calendar access powers upcoming events.")
                Text("Automation access powers Music and Spotify controls.")
                Text("Dropped files stay local through security-scoped bookmarks.")
                Text(NotchBrand.affiliationDisclaimer)
            }
            .font(.system(size: 12))
            Spacer()
            Button("Start Using NotchApple") {
                settings.onboarding = OnboardingState(
                    hasCompletedFirstRun: true,
                    completedVersion: AppCore.version
                )
                onComplete(settings)
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(width: 640, height: 480)
    }
}
```

- [ ] **Step 5: Show onboarding after launch**

In `AppDelegate`, add:

```swift
private var onboardingWindowController: OnboardingWindowController?
```

After menu bar setup:

```swift
let onboarding = OnboardingWindowController()
onboarding.showIfNeeded(settings: settings.settings) { [weak self] updated in
    self?.applySettings(updated)
}
self.onboardingWindowController = onboarding
```

- [ ] **Step 6: Run tests and manual onboarding check**

Run: `swift run MacNotchTests`

Expected: PASS.

Manual:

1. Delete or temporarily move NotchApple settings JSON.
2. Run `make run`.
3. Confirm onboarding appears once.
4. Complete onboarding.
5. Relaunch and confirm onboarding does not reappear.

- [ ] **Step 7: Commit**

```bash
git add Sources/MacNotchKit/App/OnboardingState.swift Sources/MacNotchKit/App/OnboardingView.swift Sources/MacNotchKit/App/OnboardingWindowController.swift Sources/MacNotchKit/App/AppSettings.swift Sources/MacNotchKit/App/AppDelegate.swift Sources/MacNotchTests/OnboardingStateTests.swift Sources/MacNotchTests/main.swift
git commit -m "feat: add NotchApple first-run onboarding"
```

---

### Task 10: Interface and Accessibility Polish Pass

**Files:**
- Modify: `Sources/MacNotchKit/UI/NotchRootView.swift`
- Modify: `Sources/MacNotchKit/UI/DashboardLayoutView.swift`
- Modify: `Sources/MacNotchKit/UI/WideBarLayoutView.swift`
- Modify: `Sources/MacNotchKit/UI/DashboardTileChrome.swift`
- Modify: `Sources/MacNotchKit/Window/NotchWindow.swift`
- Modify: module view files under `Sources/MacNotchKit/Modules/*/*Views.swift`
- Create: `docs/qa/notchapple-accessibility-checklist.md`

**Interfaces:**
- Consumes: `NotchIconButton`, `ModuleStateViews`, `NotchTheme.tokens`.
- Produces: keyboard, VoiceOver, focus, reduced-motion, and hit-target acceptance coverage.

- [ ] **Step 1: Create accessibility checklist**

Create `docs/qa/notchapple-accessibility-checklist.md`:

```markdown
# NotchApple Accessibility Checklist

## VoiceOver

- [ ] Menu bar icon reads "NotchApple".
- [ ] Open Settings menu item reads clearly.
- [ ] Dashboard page arrows read previous and next page.
- [ ] Pin control reads pin or unpin state.
- [ ] Module tiles read title and primary state.
- [ ] Media controls read previous, play or pause, and next.
- [ ] Shelf items read file name and stale state when relevant.

## Keyboard

- [ ] Settings can be used without a mouse.
- [ ] Dashboard page navigation works with visible focus.
- [ ] Command Palette opens with its configured shortcut after Task 14.
- [ ] Escape closes transient surfaces.

## Motion and Contrast

- [ ] System Reduce Motion disables expressive spring and glow-heavy transitions.
- [ ] Studio Glass, Minimal Graphite, Aurora, and Terminal remain readable.
- [ ] Tiny icon buttons have at least 30 by 30 point hit targets.

## Empty and Permission States

- [ ] Calendar denied state explains how to grant access.
- [ ] Media unavailable state names Music and Spotify behavior.
- [ ] Code unavailable state names missing CLI requirements.
- [ ] Shelf empty state explains dropping files.
```

- [ ] **Step 2: Add accessibility labels and keyboard shortcuts**

Update primary buttons:

```swift
.accessibilityLabel("Open dashboard")
.keyboardShortcut(.return, modifiers: [])
```

For dashboard page arrows:

```swift
.accessibilityLabel(enabled ? "Next dashboard page" : "Next dashboard page unavailable")
```

For pin:

```swift
.accessibilityLabel(isPinned ? "Unpin notch panel" : "Pin notch panel")
```

For page dots:

```swift
.accessibilityLabel("Dashboard page \(i + 1) of \(pageCount)")
```

- [ ] **Step 3: Respect reduced motion**

In `NotchRootView`, read reduce motion:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

Use a helper:

```swift
private var panelAnimation: Animation {
    reduceMotion || model.appearance.motionStyle == .reduced
        ? .easeOut(duration: 0.12)
        : .spring(response: 0.34, dampingFraction: 0.82)
}
```

Replace hard-coded root animations with `panelAnimation`.

- [ ] **Step 4: Add module empty states**

For each touched module view, replace blank states with `ModuleEmptyStateView` or `ModuleErrorStateView`. Minimum launch set:

```swift
ModuleEmptyStateView(
    title: "Drop Shelf Empty",
    message: "Drop files onto the notch to keep them ready.",
    systemImage: "tray"
)
```

```swift
ModuleEmptyStateView(
    title: "No Active Track",
    message: "Start Music or Spotify to control playback here.",
    systemImage: "music.note"
)
```

```swift
ModuleEmptyStateView(
    title: "No Timers",
    message: "Create a timer to keep it visible in the notch.",
    systemImage: "timer"
)
```

- [ ] **Step 5: Run tests and manual checklist**

Run: `swift run MacNotchTests`

Expected: PASS.

Manual:

1. Run `make run`.
2. Complete every checkbox in `docs/qa/notchapple-accessibility-checklist.md`.
3. Record failures in the same file under a `## Follow-Up Fixes` section with exact file names.

- [ ] **Step 6: Commit**

```bash
git add Sources/MacNotchKit/UI/NotchRootView.swift Sources/MacNotchKit/UI/DashboardLayoutView.swift Sources/MacNotchKit/UI/WideBarLayoutView.swift Sources/MacNotchKit/UI/DashboardTileChrome.swift Sources/MacNotchKit/Window/NotchWindow.swift Sources/MacNotchKit/Modules docs/qa/notchapple-accessibility-checklist.md
git commit -m "feat: polish NotchApple accessibility and states"
```

---

### Task 11: Feature Flags and Creative Backlog

**Files:**
- Create: `Sources/MacNotchKit/App/FeatureFlags.swift`
- Create: `Sources/MacNotchTests/FeatureFlagsTests.swift`
- Create: `docs/creative/notchapple-creative-backlog.md`
- Modify: `Sources/MacNotchTests/main.swift`

**Interfaces:**
- Produces: `FeatureFlag`, `FeatureCategory`, `FeatureFlags.defaults`.
- Consumes: roadmap creative categories.

- [ ] **Step 1: Write failing feature flag tests**

Create `Sources/MacNotchTests/FeatureFlagsTests.swift`:

```swift
import MacNotchKit

func featureFlagsTests() {
    test("launch core features are enabled by default") {
        let flags = FeatureFlags.defaults
        expect(flags.isEnabled(.workspaceProfiles), "workspace profiles enabled")
        expect(flags.isEnabled(.commandPalette), "command palette enabled")
    }

    test("launch optional and labs features are disabled by default") {
        let flags = FeatureFlags.defaults
        expect(!flags.isEnabled(.focusMode), "focus mode disabled")
        expect(!flags.isEnabled(.aiWorkbench), "ai workbench disabled")
        expect(!flags.isEnabled(.notificationTriage), "notification triage disabled")
    }

    test("feature categories match roadmap") {
        expectEqual(FeatureFlag.workspaceProfiles.category, .launchCore, "workspace profiles category")
        expectEqual(FeatureFlag.dropActions.category, .launchOptional, "drop actions category")
        expectEqual(FeatureFlag.systemPulse.category, .creativeLabs, "system pulse category")
    }
}
```

Append in `main.swift`:

```swift
featureFlagsTests()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift run MacNotchTests`

Expected: FAIL because feature flag types are missing.

- [ ] **Step 3: Add feature flag model**

Create `Sources/MacNotchKit/App/FeatureFlags.swift`:

```swift
import Foundation

public enum FeatureCategory: String, Codable, Equatable, Sendable {
    case launchCore
    case launchOptional
    case creativeLabs
    case rejectedOrDeferred
}

public enum FeatureFlag: String, Codable, CaseIterable, Sendable {
    case workspaceProfiles
    case commandPalette
    case focusMode
    case aiWorkbench
    case dropActions
    case notificationTriage
    case meetingMode
    case clipboardStudio
    case systemPulse

    public var category: FeatureCategory {
        switch self {
        case .workspaceProfiles, .commandPalette:
            return .launchCore
        case .focusMode, .aiWorkbench, .dropActions:
            return .launchOptional
        case .notificationTriage, .meetingMode, .clipboardStudio, .systemPulse:
            return .creativeLabs
        }
    }
}

public struct FeatureFlags: Codable, Equatable, Sendable {
    public var enabled: Set<FeatureFlag>

    public init(enabled: Set<FeatureFlag>) {
        self.enabled = enabled
    }

    public static let defaults = FeatureFlags(enabled: [.workspaceProfiles, .commandPalette])

    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        enabled.contains(flag)
    }
}
```

- [ ] **Step 4: Add creative backlog doc**

Create `docs/creative/notchapple-creative-backlog.md`:

```markdown
# NotchApple Creative Backlog

## Launch Core

- Workspace Profiles: switch theme, module set, and default mode for Coding, Focus, Music, Meetings, and Personal.
- Command Palette: keyboard-first launcher for modules, actions, apps, folders, scripts, and coding agents.

## Launch Optional

- Focus Mode / Session Hub: combines timers, current app context, calendar, music, and distraction controls.
- AI Workbench: public-product evolution of Code, Claude, Codex, and Cursor workflows.
- Drop Actions: zip, convert, summarize, send, copy path, and handoff workflows for shelf items.

## Creative Labs

- Notification Triage.
- Meeting Mode.
- Clipboard Studio.
- System Pulse.

## Graduation Rule

A Creative Labs item can move up only when it has a clear user job, defined module boundaries, no surprise permissions, empty and denied states, keyboard and VoiceOver paths, pure logic tests where practical, and a manual macOS checklist.
```

- [ ] **Step 5: Run tests**

Run: `swift run MacNotchTests`

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add Sources/MacNotchKit/App/FeatureFlags.swift Sources/MacNotchTests/FeatureFlagsTests.swift Sources/MacNotchTests/main.swift docs/creative/notchapple-creative-backlog.md
git commit -m "feat: gate NotchApple creative expansion"
```

---

### Task 12: Workspace Profiles Launch Core Feature

**Files:**
- Create: `Sources/MacNotchKit/App/WorkspaceProfile.swift`
- Create: `Sources/MacNotchKit/App/WorkspaceProfileStore.swift`
- Create: `Sources/MacNotchTests/WorkspaceProfileTests.swift`
- Modify: `Sources/MacNotchKit/App/AppSettings.swift`
- Modify: `Sources/MacNotchKit/App/SettingsView.swift`
- Modify: `Sources/MacNotchKit/Modules/Customize/CustomizeViews.swift`
- Modify: `Sources/MacNotchTests/main.swift`

**Interfaces:**
- Produces: `WorkspaceProfile`, `WorkspaceProfileStore`, `WorkspaceProfile.defaults`.
- Consumes: `AppSettings.modules`, `AppSettings.appearance`, `AppSettings.defaultExpansionMode`.

- [ ] **Step 1: Write failing workspace profile tests**

Create `Sources/MacNotchTests/WorkspaceProfileTests.swift`:

```swift
import MacNotchKit

func workspaceProfileTests() {
    test("default profiles include public launch set") {
        let profiles = WorkspaceProfile.defaults
        expectEqual(profiles.map(\.id), ["coding", "focus", "music", "meetings", "personal"], "profile ids")
    }

    test("profile applies appearance and module enablement") {
        var settings = AppSettings.defaults
        let profile = WorkspaceProfile(
            id: "coding",
            name: "Coding",
            defaultExpansionMode: .dashboard,
            appearance: NotchAppearance.defaults,
            enabledModuleIDs: ["code", "timers", "shelf", "customize"]
        )
        profile.apply(to: &settings)
        expectEqual(settings.activeWorkspaceProfileID, "coding", "active profile")
        expectEqual(settings.defaultExpansionMode, .dashboard, "mode applied")
        expect(settings.modules.first { $0.id == "code" }?.isEnabled == true, "code enabled")
        expect(settings.modules.first { $0.id == "stocks" }?.isEnabled == false, "stocks disabled")
    }
}
```

Append in `main.swift`:

```swift
workspaceProfileTests()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift run MacNotchTests`

Expected: FAIL because `WorkspaceProfile` is missing.

- [ ] **Step 3: Add workspace profile model**

Create `Sources/MacNotchKit/App/WorkspaceProfile.swift`:

```swift
import Foundation

public struct WorkspaceProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var defaultExpansionMode: ExpansionMode
    public var appearance: NotchAppearance
    public var enabledModuleIDs: [String]

    public init(id: String,
                name: String,
                defaultExpansionMode: ExpansionMode,
                appearance: NotchAppearance,
                enabledModuleIDs: [String]) {
        self.id = id
        self.name = name
        self.defaultExpansionMode = defaultExpansionMode
        self.appearance = appearance
        self.enabledModuleIDs = enabledModuleIDs
    }

    public static let defaults: [WorkspaceProfile] = [
        WorkspaceProfile(id: "coding", name: "Coding", defaultExpansionMode: .dashboard, appearance: .defaults, enabledModuleIDs: ["code", "timers", "shelf", "customize"]),
        WorkspaceProfile(id: "focus", name: "Focus", defaultExpansionMode: .compact, appearance: .defaults, enabledModuleIDs: ["timers", "pomodoro", "reminders", "calendar", "customize"]),
        WorkspaceProfile(id: "music", name: "Music", defaultExpansionMode: .wideBar, appearance: .defaults, enabledModuleIDs: ["media", "quickToggles", "shelf", "customize"]),
        WorkspaceProfile(id: "meetings", name: "Meetings", defaultExpansionMode: .dashboard, appearance: .defaults, enabledModuleIDs: ["calendar", "reminders", "timers", "quickToggles", "customize"]),
        WorkspaceProfile(id: "personal", name: "Personal", defaultExpansionMode: .dashboard, appearance: .defaults, enabledModuleIDs: ["media", "stocks", "screenTime", "launcher", "customize"])
    ]

    public func apply(to settings: inout AppSettings) {
        let enabled = Set(enabledModuleIDs)
        settings.activeWorkspaceProfileID = id
        settings.defaultExpansionMode = defaultExpansionMode
        settings.appearance = appearance
        for index in settings.modules.indices {
            settings.modules[index].isEnabled = enabled.contains(settings.modules[index].id)
        }
    }
}
```

Create `Sources/MacNotchKit/App/WorkspaceProfileStore.swift`:

```swift
import Foundation

public final class WorkspaceProfileStore {
    public private(set) var profiles: [WorkspaceProfile]

    public init(profiles: [WorkspaceProfile] = WorkspaceProfile.defaults) {
        self.profiles = profiles
    }

    public func profile(id: String) -> WorkspaceProfile? {
        profiles.first { $0.id == id }
    }
}
```

- [ ] **Step 4: Add profile switcher to Settings and Customize**

In `SettingsView`, add a General section:

```swift
Picker("Workspace", selection: Binding(
    get: { settings.activeWorkspaceProfileID ?? "custom" },
    set: { id in
        if let profile = WorkspaceProfile.defaults.first(where: { $0.id == id }) {
            profile.apply(to: &settings)
            onChange(settings)
        }
    }
)) {
    Text("Custom").tag("custom")
    ForEach(WorkspaceProfile.defaults) { profile in
        Text(profile.name).tag(profile.id)
    }
}
```

In `CustomizeDashboardTile`, add compact profile chips:

```swift
ForEach(WorkspaceProfile.defaults) { profile in
    Button(profile.name) {
        proxy.update { profile.apply(to: &$0) }
    }
    .buttonStyle(.plain)
    .font(.system(size: 8.5, weight: .semibold))
    .accessibilityLabel("Use \(profile.name) workspace")
}
```

- [ ] **Step 5: Run tests and manual profile check**

Run: `swift run MacNotchTests`

Expected: PASS.

Manual:

1. Run `make run`.
2. Switch to Coding profile.
3. Confirm Code, Timers, Shelf, Customize are enabled.
4. Switch to Focus profile.
5. Confirm Focus-oriented modules appear and setting persists.

- [ ] **Step 6: Commit**

```bash
git add Sources/MacNotchKit/App/WorkspaceProfile.swift Sources/MacNotchKit/App/WorkspaceProfileStore.swift Sources/MacNotchKit/App/AppSettings.swift Sources/MacNotchKit/App/SettingsView.swift Sources/MacNotchKit/Modules/Customize/CustomizeViews.swift Sources/MacNotchTests/WorkspaceProfileTests.swift Sources/MacNotchTests/main.swift
git commit -m "feat: add NotchApple workspace profiles"
```

---

### Task 13: Command Palette Launch Core Feature

**Files:**
- Create: `Sources/MacNotchKit/Modules/CommandPalette/CommandPaletteModel.swift`
- Create: `Sources/MacNotchKit/Modules/CommandPalette/CommandPaletteModule.swift`
- Create: `Sources/MacNotchKit/Modules/CommandPalette/CommandPaletteViews.swift`
- Create: `Sources/MacNotchTests/CommandPaletteTests.swift`
- Modify: `Sources/MacNotchKit/App/AppSettings.swift`
- Modify: `Sources/MacNotchKit/App/AppDelegate.swift`
- Modify: `Sources/MacNotchTests/main.swift`

**Interfaces:**
- Produces: `CommandPaletteCommand`, `CommandPaletteModel.filteredCommands(query:)`, `CommandPaletteModule`.
- Consumes: `NotchModule`, `Launcher`, settings, existing module IDs.

- [ ] **Step 1: Write failing command palette tests**

Create `Sources/MacNotchTests/CommandPaletteTests.swift`:

```swift
import MacNotchKit

func commandPaletteTests() {
    test("command palette filters by title and keyword") {
        let commands = [
            CommandPaletteCommand(id: "settings", title: "Open Settings", keywords: ["preferences"], action: {}),
            CommandPaletteCommand(id: "coding", title: "Use Coding Workspace", keywords: ["code", "profile"], action: {})
        ]
        let model = CommandPaletteModel(commands: commands)
        expectEqual(model.filteredCommands(query: "pref").map(\.id), ["settings"], "keyword filter")
        expectEqual(model.filteredCommands(query: "coding").map(\.id), ["coding"], "title filter")
    }

    test("empty query returns all commands") {
        let model = CommandPaletteModel(commands: [
            CommandPaletteCommand(id: "a", title: "A", keywords: [], action: {}),
            CommandPaletteCommand(id: "b", title: "B", keywords: [], action: {})
        ])
        expectEqual(model.filteredCommands(query: "").map(\.id), ["a", "b"], "all commands")
    }
}
```

Append in `main.swift`:

```swift
commandPaletteTests()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift run MacNotchTests`

Expected: FAIL because command palette types are missing.

- [ ] **Step 3: Add model**

Create `Sources/MacNotchKit/Modules/CommandPalette/CommandPaletteModel.swift`:

```swift
import Combine
import Foundation

public struct CommandPaletteCommand {
    public let id: String
    public let title: String
    public let keywords: [String]
    public let action: () -> Void

    public init(id: String, title: String, keywords: [String], action: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.keywords = keywords
        self.action = action
    }
}

public final class CommandPaletteModel: ObservableObject {
    public let commands: [CommandPaletteCommand]

    public init(commands: [CommandPaletteCommand]) {
        self.commands = commands
    }

    public func filteredCommands(query: String) -> [CommandPaletteCommand] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return commands }
        return commands.filter { command in
            command.title.lowercased().contains(normalized)
                || command.keywords.contains { $0.lowercased().contains(normalized) }
        }
    }
}
```

- [ ] **Step 4: Add module**

Create `Sources/MacNotchKit/Modules/CommandPalette/CommandPaletteModule.swift`:

```swift
import SwiftUI

@MainActor
public final class CommandPaletteModule: NotchModule {
    public let id = "commandPalette"
    public let title = "Command Palette"
    public var isEnabled = true
    private let model: CommandPaletteModel

    public init(commands: [CommandPaletteCommand] = []) {
        self.model = CommandPaletteModel(commands: commands)
    }

    public func collapsedView() -> AnyView? { nil }
    public func expandedView() -> AnyView? { nil }

    public func dashboardTile() -> AnyView? {
        AnyView(CommandPaletteTile(model: model))
    }

    public func wideBarView() -> AnyView? {
        AnyView(WideBarItem(systemImage: "command", text: "Command Palette"))
    }

    public func activate() {}
    public func deactivate() {}
    public func refresh() async {}
}
```

Create `Sources/MacNotchKit/Modules/CommandPalette/CommandPaletteViews.swift`:

```swift
import SwiftUI

struct CommandPaletteTile: View {
    @ObservedObject var model: CommandPaletteModel
    @State private var query = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TileHeader(title: "Command Palette", systemImage: "command")
            TextField("Search commands", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.08)))
                .accessibilityLabel("Search commands")
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(model.filteredCommands(query: query), id: \.id) { command in
                        Button(command.title) { command.action() }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.86))
                            .accessibilityLabel(command.title)
                    }
                }
            }
        }
        .padding(12)
    }
}
```

- [ ] **Step 5: Register module and default setting**

Add to `AppSettings.defaults.modules` near Code:

```swift
ModuleSetting(id: "commandPalette", isEnabled: true),
```

Add title in `AppDelegate.moduleTitles`:

```swift
"commandPalette": "Command Palette",
```

Register in `AppDelegate.registerModules()`:

```swift
registry.register(CommandPaletteModule(commands: defaultCommands()))
```

Add helper:

```swift
private func defaultCommands() -> [CommandPaletteCommand] {
    [
        CommandPaletteCommand(id: "open-settings", title: "Open Settings", keywords: ["preferences"]) { [weak self] in
            self?.settingsWindowController?.show()
        },
        CommandPaletteCommand(id: "toggle-notch", title: "Toggle Notch", keywords: ["panel", "dashboard"]) { [weak self] in
            self?.notchWindow?.toggle()
        }
    ]
}
```

- [ ] **Step 6: Run tests and manual palette check**

Run: `swift run MacNotchTests`

Expected: PASS.

Manual:

1. Run `make run`.
2. Open dashboard.
3. Confirm Command Palette tile appears.
4. Search "settings".
5. Activate Open Settings and confirm Settings opens.

- [ ] **Step 7: Commit**

```bash
git add Sources/MacNotchKit/Modules/CommandPalette Sources/MacNotchKit/App/AppSettings.swift Sources/MacNotchKit/App/AppDelegate.swift Sources/MacNotchTests/CommandPaletteTests.swift Sources/MacNotchTests/main.swift
git commit -m "feat: add NotchApple command palette"
```

---

### Task 14: Direct Download Packaging and Notarization Flow

**Files:**
- Modify: `Scripts/package-app.sh`
- Create: `Scripts/notarize-app.sh`
- Modify: `Makefile`
- Create: `docs/release/notchapple-release-checklist.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: NotchApple public bundle name from Task 2.
- Produces: repeatable package and notarization commands.

- [ ] **Step 1: Add notarization script**

Create `Scripts/notarize-app.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DMG="$ROOT/build/NotchApple.dmg"

if [[ ! -f "$DMG" ]]; then
  echo "Missing $DMG. Run make package first." >&2
  exit 1
fi

: "${APPLE_ID:?Set APPLE_ID}"
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID}"
: "${APPLE_APP_PASSWORD:?Set APPLE_APP_PASSWORD}"

xcrun notarytool submit "$DMG" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --wait

xcrun stapler staple "$DMG"
spctl -a -vv --type open "$DMG"
```

Make executable:

```bash
chmod +x Scripts/notarize-app.sh
```

- [ ] **Step 2: Add Makefile release helpers**

Modify `Makefile`:

```make
notarize: package
	bash Scripts/notarize-app.sh
```

Update `release` target to upload `build/NotchApple.dmg` and title `NotchApple v$(VERSION)`.

- [ ] **Step 3: Add release checklist**

Create `docs/release/notchapple-release-checklist.md`:

```markdown
# NotchApple Release Checklist

## Build

- [ ] `swift run MacNotchTests` passes.
- [ ] `make clean package` creates `build/NotchApple.app`.
- [ ] `build/NotchApple.dmg` exists.
- [ ] App opens from the packaged build.

## Identity

- [ ] App name reads NotchApple in Finder.
- [ ] Settings title reads NotchApple Settings.
- [ ] Menu bar accessibility reads NotchApple.
- [ ] DMG volume reads NotchApple.
- [ ] Public bundle identifier is `io.notchapple.NotchApple`.

## Migration

- [ ] Existing `Application Support/MacNotch` data migrates to `Application Support/NotchApple`.
- [ ] Migration does not overwrite newer NotchApple data.

## Accessibility

- [ ] VoiceOver checklist passes.
- [ ] Keyboard checklist passes.
- [ ] Reduced motion checklist passes.
- [ ] Built-in presets pass contrast review.

## Notarization

- [ ] `make notarize` succeeds.
- [ ] Stapled DMG passes `spctl`.
- [ ] Fresh download install opens without Gatekeeper workaround.
```

- [ ] **Step 4: Update README direct-download docs**

Add:

````markdown
## Public release packaging

```bash
make clean package
make notarize
```

`make package` creates `build/NotchApple.app` and `build/NotchApple.dmg`. `make notarize` requires `APPLE_ID`, `APPLE_TEAM_ID`, and `APPLE_APP_PASSWORD`.
````

- [ ] **Step 5: Run package verification**

Run:

```bash
swift run MacNotchTests
make clean package
test -d build/NotchApple.app
test -f build/NotchApple.dmg
```

Expected: tests pass, app bundle exists, DMG exists.

- [ ] **Step 6: Commit**

```bash
git add Scripts/package-app.sh Scripts/notarize-app.sh Makefile docs/release/notchapple-release-checklist.md README.md
git commit -m "build: add NotchApple direct-download release flow"
```

---

### Task 15: Final Public Launch Verification

**Files:**
- Modify: `docs/release/notchapple-release-checklist.md`
- Modify: `docs/qa/notchapple-accessibility-checklist.md`
- Modify: `README.md`
- Modify: `website/index.html`

**Interfaces:**
- Consumes: all previous task outputs.
- Produces: launch-ready verification record.

- [ ] **Step 1: Run automated suite**

Run:

```bash
swift run MacNotchTests
```

Expected: PASS with zero failures.

- [ ] **Step 2: Run identity searches**

Run:

```bash
rg -n '"MacNotch"|>MacNotch<|Quit MacNotch|MacNotch Settings|com.macnotch.app' Sources Scripts Makefile README.md website/index.html docs
```

Expected: matches only where one of these is true:

- Internal target names are being referenced.
- Legacy migration paths are being referenced.
- Historical docs explicitly label MacNotch as legacy.

- [ ] **Step 3: Run packaging**

Run:

```bash
make clean package
```

Expected: `build/NotchApple.app` and `build/NotchApple.dmg` exist.

- [ ] **Step 4: Complete manual QA**

Complete these files:

```bash
docs/qa/notchapple-accessibility-checklist.md
docs/release/notchapple-release-checklist.md
```

Expected: every launch-blocking checkbox is checked. Any unchecked item has a concrete issue filed in the checklist with file path and reproduction steps.

- [ ] **Step 5: Align website download copy**

In `website/index.html`, confirm:

```html
NotchApple
```

appears in title, nav, hero, and footer, and the download CTA points to the current `NotchApple.dmg` release artifact or release URL.

- [ ] **Step 6: Commit verification docs**

```bash
git add docs/release/notchapple-release-checklist.md docs/qa/notchapple-accessibility-checklist.md README.md website/index.html
git commit -m "docs: complete NotchApple launch verification"
```

---

## Execution Guidance

Implement tasks in order. After each task, run the listed tests, perform the listed manual checks, and commit only the files named for that task. If unrelated dirty files exist, leave them untouched.

Launch Optional features need separate focused plans after Task 11:

- Focus Mode / Session Hub.
- AI Workbench.
- Drop Actions.

Creative Labs features stay out of the public release until they graduate through the rule in `docs/creative/notchapple-creative-backlog.md`.
