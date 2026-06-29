# Google Stitch Prompt — MacNotch Landing Page

Paste the block below into Stitch. Generate as **desktop web**, then run the same prompt again with **mobile** toggled for the responsive variant.

---

## The Prompt

Design a single-page marketing site for **MacNotch**, a native macOS productivity dashboard that lives inside the MacBook's hardware notch and expands on hover into a multi-page tile interface (Code CLI panels, Media, Quick Toggles, Timers, Actions, Drop Shelf, Stocks). It runs on every notched Mac — MacBook Pro 14" / 16" (2021+), MacBook Air 13" / 15" (M2+) — and gracefully on non-notched displays.

The site exists to convert a Mac power user in under 30 seconds. It is not a SaaS landing page. It is closer to a hardware brochure for a piece of software — Linear-grade restraint, Panic.com craft, Things 3 quiet confidence. No motion theatre, no startup hype.

---

### 1. Visual Theme & Atmosphere

A **gallery-airy, hardware-product page**. Density 3, Variance 6, Motion 3. Clinical neutrals, one warm-graphite accent, a single product hero asset that does 80% of the persuasion. The page should feel like it was art-directed for a printed Apple keynote handout — not generated. Confident asymmetry. Generous vertical rhythm. No section feels "stacked"; each feels intentional.

Mood reference points (do not imitate, infer the discipline): linear.app, things.app, panic.com/nova, raycast.com, arc.net. None of those are loud. The page should read as "a small team that ships a beloved tool", not "we raised a seed round".

---

### 2. Color Palette

Exact tokens — every surface, text, and stroke must resolve to one of these. No interpolation, no gradients except where explicitly noted.

- **Paper** `#F7F6F2` — page canvas. A warm off-white. Never `#FFFFFF`.
- **Vellum** `#FBFAF7` — section bands when a subtle band is needed.
- **Surface** `#FFFFFF` — cards, screenshots frames only.
- **Ink** `#141414` — primary text. Never `#000000`.
- **Graphite** `#5C5C5A` — secondary text, captions.
- **Stone** `#A8A6A0` — tertiary text, metadata, timestamps.
- **Hairline** `rgba(20,20,20,0.08)` — all 1px borders.
- **Ember** `#C2410C` — the single accent. Burnt orange, saturation 78%. Used for: primary CTA fill, current-page dot in carousel, focus ring, the comma in the wordmark lockup. Nothing else.
- **Notch Black** `#0A0A0A` — used ONLY for rendered depictions of the physical notch hardware in product visuals.

Banned: any purple, any blue-violet, any neon, any gradient that crosses hue. No drop shadows tinted with color — only `rgba(20,20,20,0.06)` diffused soft shadows on screenshots.

---

### 3. Typography

- **Display & UI:** `Geist` (variable). Track `-0.02em` on headlines, `-0.01em` on subheads, `0` on body.
- **Mono:** `Geist Mono` — used for: version string (`v0.4.2`), the in-page code block showing the install command, and any numeric badge.
- **Banned:** Inter, SF Pro, system-ui fallback as the *intended* font, all serifs, all script fonts.

**Scale (desktop):**

- H1 (hero): `clamp(48px, 5.6vw, 76px)` / weight 540 / leading 1.02
- H2 (section): `34px` / weight 520 / leading 1.1
- H3 (card title): `19px` / weight 540 / leading 1.25
- Body: `17px` / weight 420 / leading 1.55 / Graphite color / max-width `62ch`
- Eyebrow: `12px` / weight 500 / tracking `0.14em` / uppercase / Stone color
- Caption: `13px` / weight 420 / Stone color

Hierarchy comes from **weight and color**, not size jumps. Never use `font-weight: 700+` for body weight contrast.

---

### 4. Layout & Sections (top-to-bottom)

The page is a single 1280px max-width column with `clamp(20px, 4vw, 56px)` horizontal padding. Section gap: `clamp(96px, 12vw, 160px)`.

#### Section A — Top Bar (sticky, glass)

`64px` tall. Left: wordmark **"macnotch,"** (Geist 18px, weight 540, the trailing comma in Ember). Right (in order, gap 24px): "Download", "Changelog", "FAQ", "Support" — Graphite text 14px, hover transitions to Ink. Far right: a small `EN` language toggle (Stone, 13px). Background: `rgba(247, 246, 242, 0.72)` with `backdrop-filter: blur(12px)` and a bottom Hairline.

#### Section B — Hero (asymmetric split, NOT centered)

Two columns, `7fr 5fr` ratio. Top of section.

**Left column (text, top-aligned):**

- Eyebrow: `FOR MAC · MACOS 14+`
- H1, **with inline image typography**:
  > Your notch, **[INLINE IMAGE: a tiny rounded rectangle, 56×40, showing a screenshot of the expanded notch dashboard]** is now your dashboard.
  >
  > Render the inline image as if it were a glyph — same baseline as the surrounding text, rounded 8px, hairline border, sits *between* the words "notch," and "is". Never overlap with text.
- Body (60ch max): "MacNotch hugs the hardware notch on any Mac that has one, and expands on hover into a stack of tiles you actually use — terminal, media, timers, stocks, a drop shelf for files. No menubar clutter. No Electron."
- CTA row (single primary CTA, no secondary link cluster):
  - Primary button: **"Download for Mac"** — Ember fill, Ink-on-Ember? No — white text. `48px` tall, `20px` horizontal padding, radius `999px` (pill). Mono-cased label, weight 500. Tactile `translateY(1px)` on `:active`. To the immediate right, in Graphite 13px: "Universal binary · 14 MB · macOS 14+"
- Metadata row below CTA, separated by a Hairline divider, 24px above:
  - Three lockups in a row, gap 32px. Each is Mono `15px` for the value, eyebrow `11px` for the label above. Example: `$22.99` / `ONE-TIME` — `Free` / `14-DAY TRIAL` — `Apple Silicon + Intel` / `COMPATIBILITY`. No fake review stars. No "trusted by 10,000+ users".

**Right column (product visual, top-aligned):**

A single hero asset: a high-fidelity render of the **top edge of a MacBook Pro screen**, cropped to show just the menu bar strip and the notch, with MacNotch's expanded dashboard hanging down. The render sits in front of a soft `radial-gradient(ellipse at top, #FBFAF7, #F7F6F2)` haze. No floating UI chrome. No browser frame. No "shipping in 2026" badge. The hardware itself is the visual.

If Stitch cannot render a hardware mockup, fall back to: a single `Surface` card, radius 28px, with a `rgba(20,20,20,0.06)` shadow at `0 24px 60px -20px`, containing a captioned screenshot. Caption beneath in Stone 12px Mono: `MBP 16" · M3 Max · macOS 14.4`.

#### Section C — The Notch, Mapped (compatibility band)

Full-bleed Vellum band, `120px` vertical padding.

- Eyebrow centered: `COMPATIBILITY`
- H2 left-aligned (not centered — variance 6): "Built for every Mac with a notch."
- Beneath, a **horizontal row of six small hardware silhouettes** rendered as simple line drawings in Ink at `1.5px` stroke. Each silhouette is the top edge of a Mac, with the notch shape drawn proportional to the real device. Beneath each in Mono `12px`:
  - `MBP 14" · 2021+`
  - `MBP 16" · 2021+`
  - `MBA 13" · M2 2022+`
  - `MBA 15" · M2 2023+`
  - `MBA 13" · M3 2024+`
  - `Future notch Macs`
- One-line caption in Graphite 14px below the row: "MacNotch reads each display's notch geometry at runtime, so width, height, and corner radius are always correct."

Do NOT use three equal-card layouts. Do NOT center this section.

#### Section D — Screenshot Gallery (the product, in detail)

- Eyebrow: `SCREENS`
- H2: "Six tiles. Three pages. Zero menubar icons."
- Beneath: a **horizontal scroller** of large screenshots (Surface cards, radius 24px, hairline border, `0 12px 36px -16px rgba(20,20,20,0.08)` shadow). Each card is ~560×360. Scroll-snap to each card. Show 1.5 cards visible at desktop width. Left/right chevrons in Hairline circles, only visible on hover.
- Each card has a small caption strip at the bottom: eyebrow + one sentence. Examples:
  - `PAGE 1 — CODE` / "Claude, Codex and Cursor panels in one drop-down."
  - `PAGE 2 — UTILITIES` / "Now playing, toggles, timers, actions, drop shelf."
  - `PAGE 3 — STOCKS` / "Live tickers with inline add and remove."
- **No** scroll-down arrow, **no** "swipe to explore" text, **no** auto-advance carousel.

#### Section E — What It Does (two-column zig-zag, NOT a 3-card row)

Repeated 3 times, alternating side:

- Left: short copy block (H3 + 2 sentence body + a Mono inline detail like `⌘⇧M to toggle`).
- Right: a tightly-cropped screenshot of the relevant tile, no chrome, just the tile itself on Vellum.

The three pairs:

1. **Lives where your eyes already are.** "The notch is the one piece of screen you're already looking at. MacNotch makes it useful instead of dead pixels." Detail: `Hover to expand · ⌘⇧M to toggle`.
2. **Runs on what's already shipping.** "Native Swift. No Electron, no daemon farm. Idles at under 30 MB and 0% CPU." Detail: `~28 MB RAM · Apple Silicon native`.
3. **Configurable, not customisable.** "Reorder tiles, hide tiles, set the default page. The point is restraint." Detail: `Settings → Modules`.

#### Section F — The Tabs Block (System / In Settings)

A small two-tab interactive section. Eyebrow: `UNDER THE HOOD`. The two tabs swap a single card body. Tab labels in Mono 13px. Tab body shows a **two-column key/value list** in Mono — left column Graphite, right column Ink:

- **System tab:** `Architecture · arm64 + x86_64`, `Minimum macOS · 14.0`, `Notch detection · NSScreen.safeAreaInsets`, `Memory footprint · ~28 MB`, `CPU idle · 0%`.
- **In Settings tab:** `Launch at login · Yes`, `Menu bar icon · Optional`, `Tile order · Drag to reorder`, `Per-display behaviour · Notched screen only`, `Settings location · ~/Library/Application Support/MacNotch`.

#### Section G — FAQ (accordion, no icons)

- Eyebrow: `QUESTIONS`
- H2: "Things people ask."
- 6 accordion rows. Closed state: question in Ink 17px, weight 500, a thin `+` glyph in Stone on the right. Open state: `+` rotates to `×`, body text in Graphite 16px, leading 1.6. Hairline divider between rows. NO chevrons. NO icons.
- Sample questions:
  - "Does it work on a Mac without a notch?"
  - "Does it interfere with full-screen apps?"
  - "Where are my files in the Drop Shelf stored?"
  - "Can I run it on multiple displays?"
  - "Is there a Sketch/Figma version?" (answer: no, this is a real shipping app)
  - "Does Apple allow this?"

#### Section H — Changelog (terse, dated)

- Eyebrow: `CHANGELOG`
- H2: "What changed."
- A flat list, no cards. Each entry is a row: left column `0.4.2 · 2026-06-22` in Mono 13px Graphite, right column a single-line description in Ink 15px. 4 entries visible, with a "Older releases →" link in Ember below.

#### Section I — Footer

Two rows.

- Top row: 4 columns of links (Mono 12px eyebrows, 14px Graphite links): Download / Screenshots / Changelog / Requirements · Support / Privacy / Refunds · Built with / Acknowledgements · Twitter / GitHub / RSS.
- Bottom row: Hairline divider above, then a single line: wordmark `macnotch,` on the left in Ink, "© 2026 — Made on a notched Mac." in Stone 13px on the right.

---

### 5. Motion

Almost none. The page is a print piece that happens to be HTML.

- Allowed: a `200ms` ease-out fade-in for the hero text when above the fold. The hero hardware visual gets a subtle `translateY(8px) → 0` on initial paint with the same timing.
- Section reveals: `opacity 0 → 1` only, no upward translation, threshold `0.15`, duration `400ms`, `cubic-bezier(0.22, 1, 0.36, 1)`.
- Button `:hover` — background darkens 6%. `:active` — translateY(1px). No glow, no scale.
- Accordion rows expand with `height auto` and a `220ms` ease.
- BANNED: parallax, scroll-jacking, sticky-scrub video, marquee scrolls, magnetic cursor, custom cursor, scroll-triggered counters that "count up", reveal-on-scroll for every text block.

---

### 6. Responsive (mobile, ≤768px)

- Top bar collapses to wordmark + a 16px Hairline-bordered hamburger glyph (three lines, not an icon font).
- Hero collapses to single column. The inline image in the H1 stays inline but scales to `40×28`. Hero hardware visual moves below the text, full width.
- Compatibility section: silhouettes wrap to two rows of three, never a horizontal scroll.
- Screenshot gallery: cards become full-width, scroll-snap remains.
- Zig-zag section: stacks; image first then copy, every pair.
- Tabs become a stacked single-column key/value list with the tab labels above each section.
- All buttons remain 48px tall (touch target).
- Section gap shrinks to `clamp(64px, 14vw, 96px)`.

---

### 7. Anti-Patterns — DO NOT DO ANY OF THESE

- No emojis anywhere — not in copy, not in section headers, not in the FAQ.
- No `Inter`. No system font fallback as the intended look.
- No serif fonts of any kind.
- No `#000000` and no `#FFFFFF` as the page background.
- No purple, no blue-violet, no neon.
- No glow shadows. No `box-shadow` with hue.
- No gradient text. No gradient buttons.
- No 3-equal-card feature grids.
- No floating chat bubble. No "We use cookies" banner mockup.
- No fake logos row ("As seen in TechCrunch, Wired, The Verge"). No customer avatars.
- No fake testimonials. No 5-star rating row. No "★★★★★ 4.9/5 on the App Store".
- No "Scroll to explore", no bouncing chevron, no down-arrow.
- No "Elevate", "Seamless", "Unleash", "Reimagine", "Next-gen".
- No placeholder names (no "John Doe", no "Acme Inc", no "Jane from Stripe").
- No emoji-as-icon. No icon library output (no Lucide, no Heroicons, no Feather).
- No centered hero. No centered H2s.
- No animated SVG illustrations of "the cloud" or "a laptop with floating widgets".
- No "Trusted by teams at…" row.
- No newsletter signup. No "Get notified" form.

---

### 8. Single-CTA Rule

The page has **exactly one** primary action: the "Download for Mac" button in the hero. The footer may repeat it. Nothing else is a button. Every other navigational element is a text link in Graphite.

---

### 9. Copy Voice

Plainspoken, slightly dry, no exclamation marks, no rhetorical questions in body copy. Sentences are short. The product does the work — the copy points at it.

Avoid: "Imagine a world where…", "We believe…", "Built for the way you work."
Use: declarative statements about what the app does. "MacNotch hugs the notch." "It expands on hover." "It runs on every Mac with a notch."

---

**Render this as a single page, desktop-first, then produce the mobile variant. Do not introduce any element not described above. If you would otherwise add a section to "fill space", leave the negative space.**
