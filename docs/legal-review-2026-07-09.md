# Legal review: NotchApple product + website (2026-07-09)

Practical review, not legal advice. Ranked by exposure.

## 1. Product name "NotchApple" (HIGH, action recommended before public launch)

- The name embeds "Apple" verbatim, used on software made for Apple platforms and
  marketed to Apple customers. That is squarely inside Apple's trademark
  registrations (Class 9 software) and their published guidelines, which
  prohibit third-party product names that incorporate Apple marks.
- Consequences to expect if it grows visible: App Store rejection (if ever
  submitted), domain/social takedown requests, cease-and-desist. Apple polices
  name marks aggressively and wins the likelihood-of-confusion analysis here.
- You also could not register the mark yourself, so the brand would sit on
  unownable ground.
- The previous name "MacNotch" has the same problem one notch down: "Mac" is
  also Apple's registered mark, and Apple's guidelines bar "Mac" as a name
  prefix for unrelated products.
- **RESOLVED 2026-07-09: renamed to "Topsoil".** Vetting notes: "Topiary" was
  disqualified (multiple exact-name Mac App Store apps), "Understory" was
  disqualified (funded booking platform understory.io plus understory.ai and
  others). "Topsoil" collisions are descriptive-use landscaping calculators and
  a Java geochronology tool, which leaves the mark arbitrary (strong) as
  applied to a desktop dashboard. Applied to: NotchBrand (user-facing strings,
  user agent, disclaimer), packaging (Topsoil.app / Topsoil.dmg / Info.plist
  display names), Makefile release copy, and the whole website.
  Deliberately NOT changed yet: bundle ID `io.notchapple.NotchApple` and the
  Application Support directory names (changing them re-prompts every TCC
  permission and orphans data). Flip both at the next major release with an
  AppDataMigrator step. Remaining diligence before public launch: USPTO TESS
  search for "Topsoil" in software classes, domain purchase (topsoil.app or
  similar), GitHub repo rename decision.
- What IS fine (nominative fair use): "for Mac", "requires macOS 14",
  "works on MacBook Pro". Descriptive references to compatibility are allowed;
  the site already uses them correctly. Never use the Apple logo or  glyph.

## 2. Truth-in-advertising fixes (applied to the site today)

- FAQ previously said nothing is ever fetched. Reality: Stocks fetches public
  market quotes and GitHub trending, Now Playing can fetch lyrics. Copy updated
  to say user content never leaves the Mac while naming those fetches.
- "Universal build for Apple silicon and Intel" was FALSE: `lipo -archs` on the
  built binary reports arm64 only. Site now says "Apple silicon" / "macOS 14
  Sonoma or later". If Intel support is wanted, build with
  `swift build --arch arm64 --arch x86_64` and re-verify before restoring the claim.
- Added a non-affiliation disclaimer and Apple trademark attribution to the
  site footer, plus a privacy page (site itself sets no cookies, runs no
  analytics, so no consent banner is required anywhere including the EU).

## 3. Distribution hygiene

- SwiftTerm (MIT) attribution: added `THIRD_PARTY_LICENSES.md` at the repo
  root. TODO: bundle it into the DMG / app resources in
  `Scripts/package-app.sh` so binary distributions carry the notice (MIT
  requires the notice "in all copies or substantial portions").
- The repo has NO license file. Decide one before the repo or releases go
  public: keep the code proprietary (add "All rights reserved" + a short EULA
  in the DMG) or open-source it (MIT/Apache-2.0). Your call; nothing added.
- Ad-hoc signing: fine for personal use. Public downloads will hit Gatekeeper
  walls and look sketchy; a public launch needs an Apple Developer ID +
  notarization (Apple program, USD 99/year).

## 4. Third-party marks in captures and copy (LOW, fine as is)

- Spotify, Claude, Codex, Cursor names and icons appear inside truthful
  screenshots of the running product, plus factual interop statements
  ("runs Claude, Codex and Cursor CLIs"). That is nominative fair use. Keep
  their marks out of the site chrome (only inside real captures) and this
  stays clean.
- Real AAPL/NVDA/MSFT quotes and public GitHub repo names in screenshots are
  factual public data, not a rights problem.

## 5. Not shipped, no action

- The AI concept video and the competitor-site reference screenshot live only
  in Downloads/repo-root as references; they are not on the site. Keep it that
  way (the concept video contains AI-garbled fake UI and must never be
  presented as the product).
