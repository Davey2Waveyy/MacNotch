# NotchApple Website Redesign Design

## Goal

Redesign `website/index.html` as a `NotchApple` landing page that closely follows the approved reference-faithful light cinematic direction from the attached video while using real local MacNotch product media and accurate current app content.

## Design Direction

Use a frosted white and grey cinematic surface with large centered typography, glassy sticky navigation, floating product footage, and scroll-driven reveal transitions. The page should feel Apple-adjacent through material, spacing, typography, and motion, without using the Apple logo or implying official affiliation.

The wordmark is custom text: `NotchApple`.

## Source Truth

The current app defaults in `Sources/MacNotchKit/App/AppSettings.swift` are the authoritative content:

- Quick page: Now Playing, Quick Toggles, Timers, Actions, Drop Shelf.
- Code page: Claude, Codex, Cursor command-line tools.
- Stocks page: tickers, repositories, installed coding skills.
- Optional modules in Settings: Screen Time, Pomodoro, Reminders, Calendar, Clipboard, Battery/System, Launcher, Customize.

The page must not present the AI-generated video UI as real product UI. It must use real local media:

- `website/assets/demo.mp4`
- `website/assets/demo_poster.jpg`
- `website/assets/panel_quick.webp`
- `website/assets/panel_code.webp`
- `website/assets/panel_stocks.webp`
- `website/assets/full_quick.webp`
- `website/assets/full_code.webp`
- `website/assets/full_stocks.webp`

## Page Structure

1. Sticky translucent navigation with `NotchApple` wordmark, short anchor links, and one primary download CTA.
2. Hero with huge centered type, concise product promise, and real autoplaying demo video.
3. Interactive notch deck with Quick, Code, and Stocks tabs using real panel captures.
4. Scroll-driven feature story sections for the three default pages.
5. Accuracy section that separates default pages from optional Settings modules.
6. Specs and trust section grounded in current app architecture and local behavior.
7. FAQ focused on fullscreen behavior, privacy, camera safety, no-notch fallback, and Code CLI requirements.
8. Final CTA and footer.

## Motion Requirements

- Hero and major sections reveal with transform and opacity.
- Demo media floats subtly on capable devices.
- Product tabs crossfade between real captures.
- Notch pill toggles the deck open and closed.
- FAQ opens with a small height/opacity transition.
- Respect `prefers-reduced-motion: reduce`.
- Do not use `window.addEventListener("scroll")`; use IntersectionObserver for reveals.

## Visual Constraints

- One page theme: light, frosted, off-white and cool-grey.
- One accent color used consistently.
- No Apple logo.
- No fake screenshots.
- No decorative blobs or orbs.
- No em-dash characters in visible page copy.
- Navigation must stay one line on desktop.
- Hero CTA must be visible in the first viewport.
- Mobile layout must collapse cleanly to one column.

## Verification

Completion requires:

- Search confirms no visible `MacNotch` or `macnotch` branding remains in `website/index.html`.
- Search confirms `NotchApple` appears in title, nav, hero, and footer.
- Search confirms local asset references are used instead of base64 product screenshots.
- Browser verification checks desktop and mobile screenshots, tab switching, notch toggle, FAQ interaction, and console errors.
