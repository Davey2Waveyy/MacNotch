# SEO Audit: NotchApple site (local, pre-launch) — 2026-07-09

Scope: `website/` (index.html + privacy.html), served locally; no public domain
yet, so rank/backlink/Search Console tooling was skipped by design. Audited
inline against the seo-audit skill's category weights.

## Health Score: 88 / 100 (pre-domain)

Business type: software product (macOS utility), single-page marketing site.
The score is capped by items that cannot exist until a domain is chosen
(canonical, sitemap, absolute OG URLs, HTTPS headers). On-page fundamentals,
schema, performance, and AI-readiness are strong.

## What was found and fixed during this audit

| Fix | Category | Impact |
|-----|----------|--------|
| Replaced Tailwind CDN (~300 KB render-blocking JS) with compiled 11.7 KB local stylesheet | Performance | LCP, reliability, works offline |
| Added `SoftwareApplication` JSON-LD (validated) | Schema | Rich result eligibility |
| Added `FAQPage` JSON-LD mirroring the five real FAQ answers (validated) | Schema | FAQ rich results, AI citability |
| Added `robots.txt` | Technical | Crawl control baseline |
| Added `llms.txt` with factual product summary | AI readiness | GEO / AI-answer citability |
| Completed OG/Twitter meta, `theme-color`, `og:type` | On-page | Share cards |
| Corrected false "Universal build" claim to "Apple silicon" (verified via `lipo`) | Content/Trust | Accuracy (also a legal item) |
| FAQ privacy answer made precise about network fetches | Content/Trust | Accuracy |

## Category notes

- **Technical (78)**: robots.txt present; sitemap.xml and canonical
  deliberately deferred until a domain exists (placeholders documented).
  Static host should add HSTS + caching headers at deploy time.
- **Content (85)**: copy is factual and verifiable against the app; one-page
  scope is appropriate for the product stage. No thin/duplicate content.
- **On-page (92)**: unique title/description, single H1, coherent H2 tree,
  descriptive alt text on all captures, internal links to privacy + anchors.
- **Schema (95)**: two valid JSON-LD blocks; no fabricated ratings or prices
  (price 0 matches the free GitHub release).
- **Performance (95)**: zero third-party scripts, system fonts, WebP images
  with intrinsic dimensions and lazy loading, `fetchpriority=high` hero,
  `preload=metadata` + poster on the video.
- **AI readiness (90)**: llms.txt, quotable factual bullets, FAQ semantics.
- **Images (95)**: all real captures, alt-texted, sized, WebP.

## Verification evidence

- `lipo -archs` on the shipped binary: `arm64` only.
- Both JSON-LD blocks parse as valid JSON.
- GitHub release `v0.1.0` exists, so the download CTA resolves.
- Full-page Playwright pass: no console errors, desktop + 390px mobile.
