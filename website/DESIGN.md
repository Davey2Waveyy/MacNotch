# NotchApple — Website Design System (light cinematic)

Single-file landing page: `index.html` (Tailwind CDN + inline CSS/JS). This is the
**approved July 1 direction**: frosted white and cool grey, glassy sticky nav, huge
centered type, floating REAL product captures, IntersectionObserver reveals.
The previous editorial/Things-style page is preserved at `index-editorial.html`
(design doc: `DESIGN-editorial.md`).

## Rules that shaped it
- Real captures only, produced via the app's debug hook + `screencapture`
  (see repo memory: notchctl / backdrop pipeline). Never fake CSS UI.
- One theme: light, locked. One accent: `#2e6bf6`, used sparingly.
- System font stack (SF), `ui-monospace` for micro labels. No font downloads.
- Motion: IO-driven reveals (opacity/translate/blur), CSS float loops, deck
  drawer fold (`grid-template-rows` + `cubic-bezier(.32,.72,0,1)`), tab
  crossfades. No scroll listeners anywhere. Reduced motion collapses all of it.
- No em/en dashes in copy. No MacNotch branding (repo URL is the one exception).
- Radius system: pills for interactive, 12-26px for frames/cards.

## Assets (all real, 2026-07-08 capture session)
- `hero_screen.webp` 2740x656: menu bar + expanded Quick panel (hero bezel).
- `panel_{quick,code,stocks}.webp` 2680x528: panel body crops (deck + features).
- `compact.webp` 596x1024: hover panel, tight crop.
- `widebar.webp` 2940x130: wide bar strip (full-bleed section).
- `demo.mp4` 1500x296 + `demo_poster.jpg`: expand → pages → collapse loop.

Deck stage aspect-ratio is locked to the panel crop: `2680 / 528`. If captures
are redone at another size, update `.deck-stage` and the `width/height` attrs.
