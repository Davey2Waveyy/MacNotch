# SEO Action Plan: NotchApple

## Phase 1: before/at launch (blockers for everything else)

1. **Resolve the product name** (see `docs/legal-review-2026-07-09.md`).
   Renaming after launch destroys any SEO equity built under "NotchApple";
   decide first. Critical.
2. **Choose the domain**, then in one pass: `<link rel="canonical">`, absolute
   `og:image`/`twitter:image` URLs, `sitemap.xml` (index + privacy), and the
   `Sitemap:` line in robots.txt (placeholder comment already there). High.
3. **Cut a fresh GitHub release** (v0.2.0): the linked v0.1.0 build is from
   June 25 and predates the UI overhaul the site shows. Screenshots must match
   what people download. High.
4. Deploy host config: HSTS, `Cache-Control` for `assets/`, HTTP→HTTPS. High.

## Phase 2: first weeks live

5. Dedicated 1200×630 OG image (current poster works but is 5:1). Medium.
6. Register in Google Search Console + Bing Webmaster; submit sitemap. Medium.
7. Notarized Developer ID build so download-page bounce doesn't spike off
   Gatekeeper warnings. Medium (also in legal review).

## Phase 3: content and authority

8. Changelog page (release notes double as fresh crawlable content). Medium.
9. Get listed where notch apps are compared: AlternativeTo, Product Hunt,
   awesome-mac lists, MacMenuBar directory. Low effort, real links. Medium.
10. Short comparison/FAQ content answering "notch app for Mac" queries the
    page currently touches only implicitly. Low.

## Phase 4: monitoring

11. Search Console coverage + CWV field data once traffic exists; re-run
    the audit skill against the live domain (unlocks crawl, CrUX, drift
    baseline). Ongoing.
