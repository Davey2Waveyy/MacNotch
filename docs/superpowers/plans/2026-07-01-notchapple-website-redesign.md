# NotchApple Website Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current static website with a `NotchApple` light cinematic landing page that uses real MacNotch product assets and accurate app content.

**Architecture:** Keep the implementation as a single static `website/index.html` file using Tailwind CDN, custom CSS, local assets, and a small inline script for tabs, reveal transitions, notch toggle, and nav state. Do not change native app source or asset files.

**Tech Stack:** HTML, Tailwind CDN, CSS custom properties, IntersectionObserver, local WebP and MP4 assets.

## Global Constraints

- Product brand on the website is `NotchApple`.
- Do not use the Apple logo or imply Apple affiliation.
- Use real local product media under `website/assets`.
- Default product pages are Quick, Code, and Stocks, as defined in `Sources/MacNotchKit/App/AppSettings.swift`.
- Optional modules are listed as Settings modules, not default pages.
- Respect reduced motion.
- Keep the page static and runnable via local HTTP server.

---

### Task 1: Replace Static Landing Page

**Files:**
- Modify: `website/index.html`

**Interfaces:**
- Consumes: local files in `website/assets`.
- Produces: static landing page with IDs `top`, `pages`, `accuracy`, `specs`, `faq`, and `get`.

- [ ] **Step 1: Replace the current HTML**

Write a full HTML document with:

- Metadata for `NotchApple`.
- Sticky glass navigation.
- Hero with real `assets/demo.mp4`.
- Interactive deck that references `assets/panel_quick.webp`, `assets/panel_code.webp`, and `assets/panel_stocks.webp`.
- Feature sections referencing `assets/full_quick.webp`, `assets/full_code.webp`, and `assets/full_stocks.webp`.
- Accurate copy for default and optional modules.
- FAQ details.
- Inline JavaScript for nav state, reveal activation, tab switching, and notch toggle.

- [ ] **Step 2: Run static checks**

Run:

```bash
rg -n "MacNotch|macnotch|data:image|—|–" website/index.html
```

Expected:

- No `MacNotch` or `macnotch` website branding.
- No base64 `data:image` product screenshots.
- No em-dash or en-dash characters.

Run:

```bash
rg -n "NotchApple|assets/demo.mp4|panel_quick.webp|panel_code.webp|panel_stocks.webp|full_quick.webp|full_code.webp|full_stocks.webp" website/index.html
```

Expected: all listed terms appear.

### Task 2: Browser Verification

**Files:**
- Read: `website/index.html`
- Create temporary verification scripts under `/tmp` only.

**Interfaces:**
- Consumes: local HTTP server serving `website`.
- Produces: screenshots and console/error report.

- [ ] **Step 1: Start a local static server**

Run from `website`:

```bash
python3 -m http.server 8765
```

Expected: server responds at `http://127.0.0.1:8765`.

- [ ] **Step 2: Run Playwright verification**

Use Python Playwright to:

- Load desktop viewport `1440x1100`.
- Load mobile viewport `390x844`.
- Capture screenshots.
- Click Code and Stocks tabs and assert the active product image changes.
- Click the notch button and assert the deck closes and reopens.
- Open one FAQ item and assert it expands.
- Capture console errors.

Expected: no console errors, all interactions work, screenshots show product media.

### Task 3: Completion Audit

**Files:**
- Read: `website/index.html`
- Read: screenshots under `/tmp`

**Interfaces:**
- Consumes: static search results and Playwright output.
- Produces: final requirement-by-requirement status.

- [ ] **Step 1: Verify explicit goal requirements**

Confirm:

- The page recreates the approved light cinematic aesthetic and transitions.
- The page uses real local product footage and screenshots.
- The page is accurate to current app defaults and optional modules.
- The website brand is `NotchApple`.
- The page runs locally and interactions work.

- [ ] **Step 2: Report result**

If all requirements are proven, mark the active goal complete. If any requirement is not proven, keep working.
