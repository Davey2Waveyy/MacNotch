# MacNotch — Website Design System

Single-file landing page: `index.html` (Tailwind via CDN + custom CSS/JS). **Light, editorial, Mac-native** — Things / CleanShot X / Bartender lineage. The product is a dark glass panel; the page is light so the real dark screenshots pop against it with soft realistic shadows.

## Direction
Calm, airy, lots of whitespace. Real cropped app screenshots are the centerpiece — never fake CSS recreations of the UI. Weight-and-color hierarchy, one restrained accent, no glassmorphism / orbs / grain. Reads as "a small team that ships a beloved Mac utility."

## Color
| Token | Value | Role |
|-------|-------|------|
| `paper` | `#FAFAF7` | Warm off-white canvas (never pure white) |
| `ink` | `#1A1A18` | Primary text + primary buttons |
| `graphite` | `#6B6B64` | Secondary text |
| `stone` | `#9C9C93` | Tertiary / mono labels |
| `line` | `rgba(20,20,18,0.08)` | Hairlines (`.ring-hair`) |
| `accent` | `#2E6BF6` | Single blue accent — eyebrow dot, page labels, links. Used sparingly. Primary CTAs are near-black (Apple/Things style). |

Color is carried by the screenshots, not the chrome.

## Type
- **Geist** (300–700) display + body, tight tracking (`-0.03em`) on headlines.
- **Geist Mono** for eyebrows, specs, meta, file paths.
- Headline: `clamp(2.3rem, 6vw, 4.4rem)`.

## Shadows (the Things signature)
Layered soft float: `--shadow-float` (4 stacked low-alpha shadows) + `.ring-hair` 1px edge. Screenshots float; they don't sit in heavy cards.

## Interactive notch (hero centerpiece)
CSS menu-bar + black notch pill. Real dashboard panel **drops from the notch** and **collapses back into it**. Tabs switch Quick / Code / Stocks (real screenshots, blur-masked crossfade). Built to Emil Kowalski's standards (`.agents/skills/review-animations`):
- Drawer curve `cubic-bezier(0.32,0.72,0,1)`; collapse via `grid-template-rows 1fr→0fr` (clean shrink into the notch, not an empty box).
- `transform-origin: top center` (scales from its trigger), never `scale(0)` — uses `scale(.96)` + opacity + `blur(4px)`.
- Interruptible CSS transitions (no keyframes), GPU-only (`transform`/`opacity`), durations < 460ms.
- First-time reveal: starts collapsed, expands once on scroll-in (first-time delight). `prefers-reduced-motion` → starts open, no movement. Hover motion gated behind `@media (hover:hover)`.

## Assets (`assets/`)
Real screenshots from the running app, cropped with `sharp`:
- `panel_{quick,code,stocks}.webp` — panel content only (notch rendered in CSS), for the interactive deck. Aspect `2644/464`.
- `full_{quick,code,stocks}.webp` — full strip incl. real notch, for the framed feature sections.

## Content rules (honest specs only)
Swift 6 · SwiftUI · arm64+x86_64 · macOS 14+ · ~28 MB idle · 0% CPU · notch via `NSScreen.safeAreaInsets` · fullscreen via `.fullScreenAuxiliary` + `popUpMenu`. Pages: Code (Claude/Codex/Cursor), Quick (now-playing/toggles/timers/actions/drop-shelf), Stocks.

## TODO before launch
- Wire Download / purchase links (deferred per owner — purchase flow comes later).
- Confirm `$22.99 one-time / 14-day trial` pricing.
- Optional: capture a 13"/16" hardware hero photo if a more cinematic top-of-page shot is wanted.
