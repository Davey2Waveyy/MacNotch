# NotchApple Public Product Roadmap Design

**Date:** 2026-07-01
**Status:** Approved
**Product:** NotchApple, evolved from the current MacNotch app
**Intended operator:** Fable 5

## Goal

Turn the existing MacNotch codebase into NotchApple: a public, polished, direct-download macOS productivity hub that lives in the notch. This is a directed evolution of the current app, not a rebuild. The existing shell, module registry, dashboard, compact preview, wide bar, settings store, and modules remain the foundation.

The roadmap must give Fable 5 enough direction to improve the product aggressively while preserving the working architecture and public-product quality bar.

## Product Position

NotchApple should feel like an expressive pro tool: premium, useful, customizable, and memorable without becoming gimmicky. It is a direct-download macOS app first, with Mac App Store readiness explicitly deferred because sandboxing may conflict with AppleScript media control, coding CLI workflows, terminal launch actions, file bookmarks, and other power-user modules.

The public promise:

- A customizable productivity hub that lives in the MacBook notch.
- Fast access to media, code projects, stocks, timers, reminders, shelf actions, system status, and future creative modules.
- Local-first behavior with plain-language permission explanations.
- A polished, accessible, signed and notarized direct download.

## Current Codebase Foundation

The current app already includes the architecture needed for this roadmap:

- `AppSettings` persists module settings, launch-at-login, and default expansion mode.
- `ModuleRegistry` composes modules without the window knowing module internals.
- `NotchModule` defines the feature boundary for collapsed, compact, dashboard, and wide-bar surfaces.
- `NotchRootView`, `DashboardLayoutView`, and `WideBarLayoutView` are the main user surfaces.
- `CustomizeModule` already exists as an in-notch settings shortcut.
- Current default pages include Quick utilities, Code CLI tools, and Stocks.
- Optional modules include Screen Time, Pomodoro, Reminders, Calendar, Clipboard, Battery/System, Launcher, and Customize.

Fable must keep this foundation unless a specific task explicitly changes it.

## Pillars

### 1. Identity

Migrate the public product from MacNotch to NotchApple.

Required public rename coverage:

- App display name.
- Menu bar accessibility description.
- Settings window title.
- Dashboard header.
- Customize tile header.
- Menu labels, including quit action.
- Package and DMG naming.
- README, website, release notes, manual test checklist, and permission copy.
- User-facing errors and empty states.

Internal Swift symbols do not need to be fully renamed in the first pass. Keeping names like `MacNotchKit`, `MacNotchApp`, or the existing package structure is acceptable when it reduces churn. Public identity comes first; deep internal renaming can be a later cleanup phase.

### 2. Personalization

Turn Customize from a toggle tile into a real Design Studio.

The Customize dashboard tile should remain fast and in-context. The full Settings window should gain a richer Design tab with previews, presets, controls, reset behavior, and profile management if it fits cleanly.

Add a persistent `NotchAppearance` model with these capabilities:

- Theme preset.
- Accent color.
- Glass intensity.
- Panel density.
- Corner style.
- Motion style.
- Dashboard layout preference.
- Menu bar icon style.

Launch with a small set of excellent presets:

- **Studio Glass:** expressive default, black glass, cyan-blue accent, premium motion.
- **Minimal Graphite:** quieter native utility feel with restrained contrast.
- **Aurora:** richer accent color and glow while staying tasteful.
- **Terminal:** sharper contrast and mono accents for Code workflows.
- **Paper:** light translucent mode for users who prefer a bright surface.

Every preset must pass contrast checks and respect reduced motion.

### 3. Interface Quality

Polish every user-facing surface, not only the dashboard.

Required surfaces:

- Compact hover preview.
- Dashboard.
- Wide Bar.
- Settings window.
- Menu bar menu.
- First-run onboarding.
- Empty states.
- Permission states.
- Error states.
- Module loading states.

Key improvements:

- Clearer compact hierarchy and pinned state.
- Better dashboard page identity, navigation, grouping, tile rhythm, and active mode indicators.
- Wide Bar made useful as a glanceable status strip.
- Settings reorganized into public-product sections: General, Modules, Design, Privacy, Shortcuts, and About.
- Menu bar actions renamed and expanded for NotchApple: Open NotchApple, Open Settings, switch mode, pause or hide, and quit.
- First-run onboarding that explains permissions before macOS prompts appear.
- Centralized motion values so expressive, calm, and reduced motion styles behave consistently.

### 4. Accessibility

Accessibility is part of the public launch bar, not a cleanup task.

Required acceptance criteria:

- VoiceOver labels for menu bar item, panel controls, module tiles, navigation arrows, page dots, toggles, transport controls, shelf items, and module actions.
- Keyboard navigation for dashboard controls, settings, module actions, pin/unpin, mode switching, and pagination.
- Visible focus states that match the active theme.
- Reduced motion support that disables floating, glow-heavy, or spring-heavy transitions and falls back to simple fades or resizes.
- Contrast checks for every built-in preset.
- Larger hit targets for tiny controls such as lock, arrows, remove buttons, play/pause, and tile actions.
- Text truncation rules so compact and dashboard tiles never become unreadable.
- Plain-language permission and denied states.
- Manual checks for VoiceOver, keyboard-only use, reduced motion, and high contrast.

### 5. Creative Expansion

Fable may propose new modules and features. Ideas must be categorized before implementation:

- **Launch Core:** required for the public release.
- **Launch Optional:** may ship if complete, polished, and off by default or feature-flagged where appropriate.
- **Creative Labs:** prototype or backlog item, not required for public release.
- **Reject/Defer:** interesting but outside the product direction.

Creative freedom is encouraged inside the NotchApple product direction. Fable may rename module concepts, reshape workflows, propose visual treatments, suggest new module groupings, create launch screenshot moments, and prototype optional features behind flags.

High-value module and feature candidates:

- **Focus Mode / Session Hub:** combines timers, current app context, calendar, music, and distraction controls into a "now working" state.
- **Command Palette:** keyboard-first launcher for modules, actions, apps, scripts, folders, and coding agents.
- **AI Workbench:** public-product evolution of Code, Claude, Codex, and Cursor tooling with projects, agent status, terminal launch, and safe command affordances.
- **Drop Actions:** extend Drop Shelf into zip, convert, summarize, send, copy path, and handoff workflows where feasible.
- **Notification Triage:** glanceable priority queue, preferably manual or privacy-preserving first.
- **Meeting Mode:** next meeting, join button, mic/camera checks, and focus timer.
- **Clipboard Studio:** recent clips, pinned favorites, text transforms, and sensitive-snippet redaction.
- **System Pulse:** polished battery, network, CPU, memory, and thermal dashboard.
- **Workspace Profiles:** switch layout, theme, and modules for Coding, Focus, Music, Meetings, and Personal.

A new feature graduates from Creative Labs only when it has:

- A clear user job.
- Clear module boundaries.
- No surprise permissions.
- Good empty, denied, offline, loading, and error states.
- Keyboard and VoiceOver paths.
- Fit with built-in themes.
- Pure logic tests where practical.
- A manual checklist for live macOS behavior.

### 6. Direct Distribution

Public distribution targets direct download first.

Release goals:

- Signed and notarized `.app`.
- Polished `.dmg` with drag-to-Applications layout.
- Repeatable release script.
- Versioned release notes.
- Website download CTA aligned with the current app version.
- Privacy and permission documentation.
- Gatekeeper right-click instructions only as fallback, not the normal install path after notarization.

Mac App Store readiness is deferred.

## Bundle, Storage, and Migration

Define a new public bundle identity for NotchApple.

Recommended strategy:

- Introduce a public bundle identifier for NotchApple.
- Migrate existing user data from `Application Support/MacNotch` to `Application Support/NotchApple` on first NotchApple launch.
- Preserve settings, appearance, shelf items, code projects, reminders, launcher data, and screen-time data where possible.
- Keep a one-time migration marker so migration is idempotent.
- Leave old MacNotch local builds operational during development when possible.
- Document that development builds may maintain separate local identities until the public identity stabilizes.

Data migration must be tested before public release.

## Trust and Privacy

NotchApple must explain what it does before asking for trust.

Required trust surfaces:

- Onboarding explains what the notch panel is, how it opens, and what default modules are enabled.
- Onboarding explains permissions before macOS prompts appear.
- Privacy section explains local-first behavior.
- Module docs list data sources, including AppleScript, EventKit, file bookmarks, coding CLIs, stock APIs, and local settings.
- Copy makes clear that NotchApple is not affiliated with Apple.
- No cloud sync or background upload implication unless implemented.

Permission prompts and denied states must be plain, specific, and actionable.

## Shared UI and Architecture Additions

Add abstractions only where they support the roadmap.

Recommended additions:

- `NotchAppearance`: persisted design settings.
- `NotchBrand`: product name, visible copy constants, bundle/storage names, and affiliation disclaimer text.
- `NotchOnboardingState`: first-run status, migration status, and completed setup steps.
- Feature flag or labs config for experimental Fable modules.
- Shared UI primitives: `NotchButton`, `NotchIconButton`, `NotchSegmentedControl`, `NotchToggle`, `NotchFocusRing`, `ModuleEmptyState`, and `ModulePermissionState`.

Module internals should remain independent. Shared UI helpers provide consistent chrome, accessibility, theme use, and error-state patterns.

## Error-State Standard

Every module should intentionally render these states when relevant:

- Ready.
- Loading.
- Empty.
- Permission needed.
- Permission denied.
- Offline or unavailable.
- Error with retry or explanation.

No public screen should silently fail, render an unexplained blank tile, or show raw technical errors.

## Phases

### Phase 1: Foundation Rename and Product Hygiene

Goal: Make the product visibly and operationally NotchApple without destabilizing the app.

Scope:

- Public rename from MacNotch to NotchApple.
- Brand constants.
- Menu bar copy.
- Settings title.
- Dashboard and Customize copy.
- README and release copy.
- Bundle and storage migration design.
- Baseline tests.

Exit criteria:

- No visible public MacNotch branding remains in the app or docs intended for launch.
- Existing modules still load in their current order.
- Settings load and save.
- Direct development build still runs.

### Phase 2: Customization System

Goal: Build the Design Studio and app-wide appearance model.

Scope:

- `NotchAppearance` persistence and defaults.
- Theme presets.
- Accent swatches.
- Glass, density, corner, motion, and layout controls.
- Customize dashboard tile upgrades.
- Settings Design tab.
- Theme application across compact, dashboard, wide bar, and shared components.

Exit criteria:

- Built-in presets are selectable and persistent.
- Each major surface responds to theme changes.
- Reduced motion overrides expressive motion.
- Presets meet contrast acceptance criteria.

### Phase 3: Interface and Accessibility Polish

Goal: Raise all existing surfaces to public-product quality.

Scope:

- Compact preview polish.
- Dashboard navigation and page identity.
- Wide Bar utility pass.
- Settings reorganization.
- Onboarding.
- Menu bar improvements.
- Shared empty, permission, loading, and error states.
- Keyboard, VoiceOver, focus, contrast, and hit target work.

Exit criteria:

- Keyboard-only path exists for core controls.
- VoiceOver labels exist for primary controls.
- Reduced motion is honored.
- Major empty and denied states are understandable.
- Manual accessibility checklist passes.

### Phase 4: Creative Product Expansion

Goal: Let Fable expand the product with new modules and workflows while protecting launch quality.

Scope:

- Fable proposes module and feature concepts.
- Each concept is tagged Launch Core, Launch Optional, Creative Labs, or Reject/Defer.
- Select a launch set.
- Prototype optional ideas behind flags when needed.
- Promote only polished ideas to launch.

Exit criteria:

- Creative backlog exists and is ranked.
- Launch module set is explicit.
- Any shipped new feature meets the feature quality bar.
- Experimental work does not block the public release.

### Phase 5: Public Direct Download

Goal: Ship NotchApple as a trustworthy direct-download app.

Scope:

- Signed and notarized app.
- Polished DMG.
- Versioned release flow.
- Privacy and permission docs.
- Website alignment.
- Manual install and upgrade checklist.
- Regression pass across existing modules.

Exit criteria:

- Clean build packages successfully.
- Notarization flow succeeds.
- Fresh install opens normally.
- Existing local data migrates where applicable.
- Website and app version match.
- Release checklist passes.

## Testing Requirements

Automated tests:

- Settings migration.
- Appearance defaults.
- Theme preset definitions.
- Storage migration.
- Feature flag behavior.
- Pure module logic changed by this roadmap.
- Brand constant behavior where practical.

Manual verification:

- Compact, dashboard, wide bar, settings, onboarding, and menu bar.
- All built-in presets.
- VoiceOver.
- Keyboard-only use.
- Reduced motion.
- High contrast.
- Media controls.
- Code workflows.
- Stocks.
- Drop Shelf.
- Timers.
- Reminders.
- Calendar.
- Launcher.
- Quick toggles.
- Direct packaging and install.

## Fable 5 Operating Rules

Fable must follow these rules:

- Do not rebuild the app from scratch.
- Preserve the existing module architecture unless a task explicitly changes it.
- Prefer incremental phases with visible wins.
- Keep public identity and user trust above novelty.
- New features are welcome, but must be categorized and gated.
- Every shipped surface must include accessibility and error-state acceptance criteria.
- Every phase should end with a testable, releasable increment.
- Creative freedom belongs inside the NotchApple product direction.
- Avoid churny internal renames unless they reduce real confusion or support the public identity.
- Keep Mac App Store constraints out of the direct-download launch unless a later plan explicitly reopens them.

## Out of Scope

- Full internal package/type rename in the first public-product pass.
- Mac App Store release.
- Cloud sync.
- Rebuilding the windowing architecture from scratch.
- Replacing all existing modules with new concepts.
- Promising system-level notification access or private APIs without a clear feasibility and privacy review.

## Implementation Defaults

Use these defaults unless the user explicitly overrides them before implementation:

- Public bundle identifier: `io.notchapple.NotchApple`.
- Public executable and packaged app name: `NotchApple` in Phase 1.
- Internal library and test target names may remain `MacNotchKit` and `MacNotchTests` during the first public-product pass.
- Paper ships after Studio Glass, Minimal Graphite, Aurora, and Terminal pass contrast and visual checks. If it slows Phase 2, keep Paper hidden until the next polish pass.
- Phase 4 Launch Core candidates: Workspace Profiles and Command Palette.
- Phase 4 Launch Optional candidates: Focus Mode / Session Hub, AI Workbench, and Drop Actions.
- Phase 4 Creative Labs candidates: Notification Triage, Meeting Mode, Clipboard Studio, System Pulse, and any additional Fable-generated concepts.
- Profile import/export is deferred from the first Design Studio phase unless it falls out naturally from the profile persistence model.
