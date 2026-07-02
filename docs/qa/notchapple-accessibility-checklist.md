# NotchApple Accessibility Checklist

> **Manual pass pending (human).** Every item below requires a GUI run
> (`make run`) with VoiceOver / Full Keyboard Access / Reduce Motion enabled.
> Nothing has been checked off yet. Record failures under `## Follow-Up Fixes`
> with exact file names.

## VoiceOver

- [ ] Menu bar icon reads "NotchApple". (`MenuBarController.swift` sets `accessibilityDescription`)
- [ ] Open Settings menu item reads clearly.
- [ ] Dashboard page arrows read previous and next page, including "unavailable" when disabled. (`DashboardLayoutView.swift`)
- [ ] Pin control reads pin or unpin state. (`NotchRootView.swift`, `DashboardLayoutView.swift`)
- [ ] Page dots read "Dashboard page N of M". (`DashboardLayoutView.swift`)
- [ ] Module tiles read title and primary state.
- [ ] Media controls read previous, play or pause, and next. (`MediaViews.swift`)
- [ ] Shelf items read file name, and "file unavailable" when the bookmark no longer resolves. (`ShelfViews.swift`)
- [ ] Onboarding title reads as a heading; permission bullets read as one grouped element. (`OnboardingView.swift`)

## Keyboard

- [ ] Settings can be used without a mouse.
- [ ] Dashboard page navigation works with visible focus.
- [ ] Command Palette opens with its configured shortcut after Task 14.
- [ ] Escape closes the expanded notch panel when it is key (after a click opened it). (`NotchWindow.swift` `cancelOperation`)
- [ ] Escape while a text field is focused (Stocks ticker input, Reminders input): verify whether the
      field editor consumes it or the whole panel collapses — behavior is currently unpinned; record
      the observed behavior and whether it feels correct.
- [ ] Onboarding primary button activates with Return. (`OnboardingView.swift` `.keyboardShortcut(.defaultAction)`)

## Motion and Contrast

- [ ] System Reduce Motion disables expressive spring and glow-heavy transitions
      (panel expand/collapse, dashboard page slide, timer firing pulse, media waveform).
- [ ] Studio Glass, Minimal Graphite, Aurora, and Terminal remain readable.
- [ ] Tiny icon buttons have at least 30 by 30 point hit targets
      (dashboard nav arrows, header pins, timer +/- steppers, media transport).

## Empty and Permission States

- [ ] Calendar denied state explains how to grant access.
- [ ] Media unavailable state names Music and Spotify behavior. (`MediaViews.swift`)
- [ ] Code unavailable state names missing CLI requirements.
- [ ] Shelf empty state explains dropping files. (`ShelfViews.swift`)
- [ ] Timers tile explains creating a timer when none are running. (`TimersViews.swift`)

## Follow-Up Fixes

- Escape only reaches the notch panel while it is the key window (a click that
  opened the dashboard makes it key; a hover-opened compact preview is not key,
  and dismisses on mouse-out instead). Global Escape handling would require an
  event tap — deliberately not built.
- The app has no main menu (menu-bar app), so Cmd-W does not close the Settings
  window; the titlebar close button and Escape-per-macOS-defaults are the exits.
  If keyboard-only close is required, add a key equivalent in
  `SettingsWindowController.swift`.
- The compact panel's Media row keeps its one-line "Nothing playing" text
  (`MediaViews.swift` `MediaExpandedView`) — the full `ModuleEmptyStateView`
  is used on the dashboard tile; the compact strip is height-constrained.
