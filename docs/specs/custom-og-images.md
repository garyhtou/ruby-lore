# Spec & Plan: Custom per-page Open Graph images

Status: **Draft for review (v2, incorporates multi-reviewer feedback)** · Owner: Gary Tou · Target branch: `claude/custom-og-images-spec-fnb6vu`

> This is a spec and implementation plan only. No feature code ships until this
> document is approved.

## 1. Summary

Ruby Lore currently serves one site-wide social share image
(`src/images/og-share.png`, 1200×630) for every page. This spec proposes
generating a **unique, on-brand Open Graph / Twitter image per page at build
time**, so that every card (people, stories, talks, glossary terms, timeline
releases) and every templated section page gets a share image bearing its own
title. The default image remains as a fallback and for pages we don't template.

The work is scoped to **image generation + metadata wiring**; it does not change
site content or routing.

## 2. Motivation & goals

Ruby Lore's stated goals are SEO, "AI SEO", and shareability. This feature is
**primarily a shareability feature** with modest, honest SEO hygiene benefits:

- **Shareability (primary win).** A link to `/people/matz/` unfurled in Slack,
  Discord, iMessage, X, LinkedIn, WhatsApp, Telegram, or Mastodon currently
  shows the same generic card as the home page. A title-bearing, branded card
  makes shares self-describing and lifts click-through. This is the reason to do
  the work.
- **SEO (hygiene, not ranking).** `og:image` is **not** a Google ranking
  factor. The real, low-cost SEO wins bundled here are structured-data
  correctness: giving the site an `Organization.logo` (a genuine search
  feature / knowledge-panel signal, currently absent), promoting the per-card
  JSON-LD `image` to a dimensioned `ImageObject`, and keeping that image in sync
  with the actual per-page image (today `json_ld.rb` hardcodes the site-wide
  image, see §6). Correct `og:image:width/height/alt` also clears warnings in
  social/link debuggers.
- **AI SEO (be honest).** LLM/answer-engine crawlers weight **text and
  structured entity data**, not share images. The AI-crawler allowlist in
  `robots.txt` already does the actual AI-SEO heavy lifting. We do **not** claim
  images (or image `alt`) meaningfully move answer-engine ranking. `og:image:alt`
  is valuable for **accessibility and Google Images**, framed as such, not as
  an AI-crawler entity signal. The JSON-LD image work's benefit is **rich-results
  correctness** (not shipping a stale/generic image), not answer quality.

### Success criteria

1. Every **templated** page emits a `1200×630` PNG `og:image` unique to that
   page. (Untemplated pages, credits, 404, 500, and any type without a
   template, correctly serve the shared default; see §11/§13.)
2. `og:image`, `twitter:image`, `og:image:width/height/type`, and `og:image:alt`
   are present and mutually consistent on every page; the JSON-LD `image` is
   present and consistent **on card pages** (the only pages that carry an
   image-bearing node today, see §6/§9).
3. Any page without a generated image falls back cleanly to `og-share.png`. A
   **failed or evicted render is caught by CI as a loud build failure**, not
   silently masked (see §9 B-checks), "never a broken image" means *CI blocks
   it*, not *the template rescues a missing file*.
4. Images render correctly across the social-preview matrix (§9).
5. The build is **byte-stable on the canonical build platform (linux-x64)**,
   same input → same bytes on that platform. (Cross-architecture byte-identity
   is explicitly *not* guaranteed; see §8.)
6. No regression to existing CI gates (html-proofer, bundle-size, zero-JS
   content, JSON-LD validity).
7. The `_why` anonymity constraint (R31) is preserved (§10).

### Non-goals

- Runtime/on-demand image generation (impossible on our host, see §4).
- Animated, video, or per-viewer-personalized images.
- Light/dark *variants* of the share image (social platforms don't send a color
  scheme; we ship one canonical look, see §7).
- Redesigning the existing default `og-share.png` (but see §7 note m on keeping
  it visually consistent).

## 3. Current state (grounded in the codebase)

- **Generator:** Bridgetown 2.2, ERB templates. Cards are a collection
  (`collections: { cards: ... }`, `bridgetown.config.yml`) rendered with the
  `card` layout. Card permalink is directory-derived (`permalink: /:path/`),
  **not** derived from `Slugs::TYPE_SEGMENTS`.
- **Build lifecycle** (`Bridgetown::Site#process`):
  `reset → read → generate → render → cleanup → write`, then
  `hook :site, :post_write`. **`cleanup` runs after `render` and before
  `write`** and removes any file in `output/` that isn't a registered resource /
  static file / generated page / `keep_files` entry. This is load-bearing for
  §5.
- **OG wiring today:** `src/_partials/_head.erb` computes a single
  `share_image_url = "#{site.config.url.chomp('/')}/images/og-share.png"` (an
  **absolute** URL) and emits `og:image` + `twitter:image`. It already computes
  per-page `og_title`, `page_description` (summary → hook → site description),
  `og_type` (`article` for cards, else `website`), and a trailing-slash-guarded
  `page_url`. A comment there flags per-page images as "a later, optional
  enhancement."
- **JSON-LD:** `src/_components/json_ld.rb` has its **own** duplicated
  `share_image_url` helper, used **only** inside `card_nodes` → the `Article`
  `#webpage` node. Section pages (home, `/glossary/`, `/timeline/`, `/people/`,
  `/stories/`, `/talks/`, `/start-here/`, credits, 404/500) emit only `WebSite`
  + `Organization` (+ glossary set) and **carry no `image` node**. There is no
  `Organization.logo` today. Its comment: "if per-page OG images ever land,
  update both call sites."
- **Card model:** front matter carries `type`, `title`, `hook`, optional
  `summary` (**no card currently sets `summary`**, all 17 use `hook`),
  optional `dates`, `sources`, optional `aka`/`identity_urls`. Routing types
  (`Slugs::TYPE_SEGMENTS`): `person`→people, `story`→stories, `talk`→talks,
  `vocabulary`→glossary, `release`→timeline. `script/validate.rb` **also allows**
  `artifact, institution, book, program` (none exist yet, and none are mapped in
  `TYPE_SEGMENTS` or `JSONLd::PER_TYPE_SCHEMA`).
- **Brand tokens** (`frontend/styles/tokens.css`): parchment `#f7f1e6`, ink
  `#241f1c`, garnet `#9b1b30` / deep `#7a1526`, fox `#d2662a`, brass **rule**
  `#b08d57`, brass **text** `#7a5e34` (the token used precisely because raw
  brass fails as text). Fonts: **Fraunces** (display), **Literata** (body),
  **JetBrains Mono**, self-hosted `woff2` in `src/fonts/`. Fox mark:
  `src/images/fox.svg` (note: its face fill `#faf4ea` is near-parchment).
- **Build/deploy:** `.github/workflows/ci.yml` builds with `npm ci` →
  `npm run esbuild` → `bundle exec bridgetown build`, then gates: `validate.rb`,
  `check_bundle_size.rb` (JS-only; unaffected by images), `check_no_js_content.rb`,
  `check_json_ld.rb`, and **html-proofer over `output/`** run with
  `--disable-external` and the *default* check set. `pages.yml` rebuilds from
  scratch and deploys `output/` after CI passes. `scheduled-build.yml` rebuilds
  periodically **specifically to surface build/dependency rot**. Ruby 4.0 and
  Node 22 are both present in all three workflows. `BRIDGETOWN_ENV=production` for
  the canonical build. `.gitignore` already ignores `output` and `/tmp/*`.

**Hard constraint:** `chunkybacon.dev` is GitHub Pages, DNS-only (not
Cloudflare-proxied, see `docs/deploy.md`), so there is **no server or edge
worker** in the request path. All image generation must happen **at build
time**.

## 4. Approach options

| Option | How | Verdict |
| --- | --- | --- |
| **A. Satori + resvg (build-time, JS)** | Render a template → SVG (`satori`) → PNG (`@resvg/resvg-js`). Runs in Node, no browser. | **Recommended.** |
| B. Headless Chromium (Playwright/Puppeteer) | Render a real HTML page per image and screenshot it. | Rejected: heavier CI, and screenshot bytes vary by platform/font hinting far more than resvg. |
| C. Ruby-native (SVG template → resvg/librsvg, or ImageMagick) | Build an SVG per page in a Ruby builder and rasterize. | Documented fallback (§12) if the Node↔Ruby boundary proves painful; rejected as primary because SVG has no text auto-wrap and it's more bespoke than the well-trodden satori path. |
| D. Hand-designed static images per page | Design each in Figma, commit PNGs. | Rejected: doesn't scale, drifts from content, no automation. |

### Why Option A

No runtime host needed (pure build step, fits GitHub Pages); fits the existing
Node 22 + npm toolchain already first-class in CI (esbuild); fast (hundreds of
images/sec, no browser boot); the Vercel-OG lineage, well-documented and
maintained; and **deterministic on a fixed platform**, resvg does its own
rasterization (tiny-skia + fontdb, no system-font/hinting dependency), so
same-version + same-platform output is byte-stable (see §8 for the
cross-platform caveat).

## 5. Recommended architecture

### 5.1 Two-phase generation (respects the Bridgetown lifecycle)

Metadata assignment and byte generation **must be split across the
render→cleanup→write boundary**, because the metadata must exist *before*
`render` but the PNG bytes must be written *after* `cleanup` (which would
otherwise delete unregistered files from `output/`). A single Ruby builder
(`plugins/builders/og_images.rb`, in the codebase's existing `SiteBuilder`
style) registers two hooks:

**Phase A, `hook :site, :pre_render` (fires once, after `generate`, before any
resource renders):**
1. Walk `site.collections.cards.resources` and the templated standalone pages in
   `site.collections.pages.resources` (home/people/stories/talks/glossary/
   timeline/start-here). **Skip** resources whose `relative_url` does not end in
   `/` (e.g. `404.html`, `500.html`) and any card `type` without a template,
   those keep the default. Also skip pages the design chooses to leave on the
   default (credits/error pages, §11).
2. For each selected resource compute the OG model:
   `{ kind, slug, title, supporting_text, kicker, content_hash, out_path }`
   (see §5.2, §7 for `kicker`/`supporting_text` rules).
3. Assign onto the resource so templates can read it:
   `resource.data.og_image` = the **absolute** URL (§5.2), and
   `resource.data.og_image_alt` = the alt string (§6). `resource.data` is a
   mutable `HashWithDotAccess::Hash`, dot-accessible from `_head.erb` and from
   `json_ld.rb` (which already reads `@resource.data`). **This is the single
   source of truth** both call sites read, no formula is duplicated.
4. Append the entry to an in-memory manifest.

**Phase B, `hook :site, :post_write` (fires after `cleanup` + `write`):**
5. Write the manifest to `tmp/og-manifest.json` and shell out **once**:
   `node script/og/render.mjs tmp/og-manifest.json` (batch render, one process).
   The renderer, per entry: if `tmp/og-cache/<hash>.png` exists, reuse it; else
   render and store it there; then copy the PNG to `output/og/<...>.png`
   (i.e. into `site.dest`). Files written here are **after** `cleanup`, so they
   survive to the deploy artifact.
6. On any per-image failure the renderer exits non-zero and the build fails
   loudly (the ERB never depends on the Node process having run, it only reads
   the deterministic path computed in Phase A).

> **Handoff decision (was an open question):** use `resource.data.og_image`
> (Phase A). A `site.data` registry works but reintroduces a lookup the resource
> already carries; deriving the hash in the ERB partial is rejected (it would
> duplicate renderer internals in a template and break the fallback signal).

### 5.2 Filenames & URLs

- **Stored value:** the builder stores the **absolute** URL on
  `resource.data.og_image`, e.g.
  `https://chunkybacon.dev/og/people/matz-a1b2c3d4.png`, composed once from
  `site.config.url` (mirroring the existing `share_image_url` construction).
  `og:image`/`twitter:image` **must** be absolute; `json_ld.rb` reads the same
  stored absolute value (no second origin-prepend, closing the drift hazard the
  code comments warn about). Note `resource.absolute_url` is **not** usable here
 , it resolves the resource's own permalink, not an asset path.
- **Path shape:** `/og/<kind>/<slug>-<hash8>.png`. `<kind>` is the card `type`
  for cards (`people`→ use the type name `person`, etc., pick one convention
  and keep it stable) and `pages` for section pages (`/og/pages/home-….png`).
  Section pages carry no `type`, so the builder holds an explicit
  filename→`{kind,kicker,supporting_text}` map for them.
- **`<hash8>`** = first 8 hex of the content hash (§8). The content hash in the
  filename is deliberate: social platforms cache `og:image` URLs hard, so a
  changed title/hook changes the URL and forces re-unfurl. Trade-off: a consumer
  holding a *stale* image URL gets a 404 after the next deploy, acceptable
  because the HTML always points at the current hash and `robots.txt` is
  allow-all so crawlers re-read the page.

### 5.3 Output & caching locations

- **PNG bytes** are written into `output/og/` **in Phase B (post-write)** and
  are **not** committed to git (consistent with `output/` being the build
  artifact; `.gitignore` already ignores `output`). They are **not** placed in
  `output/` mid-build (the cleaner would delete them, §5.1).
- **Render cache** lives in `tmp/og-cache/` (already gitignored, survives the
  Bridgetown clean). **Never** cache `output/og/`.
- If static fonts are vendored (§7), they live in `script/og/fonts/` and **are**
  committed (that path is not gitignored).

## 6. Metadata wiring

In `src/_partials/_head.erb`, replace the single `share_image_url` with the
per-page value and add supporting tags:

```erb
<% og_image_url = (resource&.data&.og_image.to_s.empty? ? share_image_url : resource.data.og_image) %>
<% og_image_alt = (resource&.data&.og_image_alt.to_s.empty? ? default_og_alt : resource.data.og_image_alt) %>

<meta property="og:image" content="<%= og_image_url %>" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta property="og:image:type" content="image/png" />
<meta property="og:image:alt" content="<%= og_image_alt %>" />
<meta property="og:locale" content="en_US" />
<meta name="twitter:image" content="<%= og_image_url %>" />
<meta name="twitter:image:alt" content="<%= og_image_alt %>" />
```

- `og_image_alt` pattern **front-loads the entity** for accessibility/Google
  Images: `"Ruby Lore · <KICKER>: <title>"` (e.g.
  `Ruby Lore · PERSON: Yukihiro "Matz" Matsumoto`). Alt uses **only**
  title + kicker, **never the hook, sources, aka, or body** (see R31, §10).
  Fallback (default-image) pages emit a generic
  `"Ruby Lore, a warm history of Ruby"`. (`<%= %>` auto-escapes attribute
  values, confirmed by `json_ld.erb` needing `<%==` for raw output, so quoted
  titles are safe in attributes.)
- **`article:*` tags for cards.** Since we already compute git-derived dates
  (`json_ld.rb#git_dates`) and set `og:type=article`, add
  `article:published_time` / `article:modified_time` (and optionally
  `article:section` from the type segment) on card pages, so `og:type=article`
  isn't declared without its companions.
- **`json_ld.rb` changes:**
  1. Replace the local `share_image_url` helper; each card's `Article.image`
     reads `@resource.data.og_image` (fallback to the default).
  2. **Promote `Article.image` to an `ImageObject`** (`{ "@type":"ImageObject",
     "url":…, "width":1200, "height":630, "caption": og_image_alt }`) so the
     structured data is self-consistent with the OG dimension tags, the values
     already exist.
  3. **Add `Organization.logo`** as an `ImageObject` pointing at a **raster**
     derivative of the fox mark (e.g. `src/images/logo-512.png`; SVG logos are
     unreliable for this, same reason we don't use SVG OG images). This is the
     highest-leverage structured-data image win and is currently absent.
  4. (Optional, lower priority) add `primaryImageOfPage` on section-page nodes
     so non-card pages expose their generated image to structured data too.
- Keep `og:url`/canonical logic exactly as-is (the trailing-slash guard is
  correct and independent of this work). `og:image:secure_url` is unnecessary
  (the URL is already absolute https).

## 7. Image design

**Canvas:** 1200×630, PNG, one canonical light look (parchment ground). Museum /
archival-plaque aesthetic matching the site. Single canonical look is correct,
platforms don't send a color scheme.

### 7.1 Geometry (an implementer must be able to build from this)

- **Safe area:** keep all essential content within a **≥60px keep-clear margin**
  on every side (essential content inside ~**1080×510**). OG images get
  corner-rounded (iMessage) and sometimes center-cropped toward ~1.91:1;
  nothing critical may touch the edge.
- **Outer edge for white backgrounds:** parchment `#f7f1e6` is within a few
  percent of white and will bleed borderlessly into X/LinkedIn light mode. Draw a
  **defined outer border that holds on white**: a ~2px **ink `#241f1c`** (or
  garnet `#9b1b30`) hairline just inside the bleed, optionally over a faint
  deeper-tone mat. A brass frame alone is **not** sufficient (brass on parchment
  is ~2.75:1, see 7.3).
- **Grid:** title block left-aligned on the left margin; lockup and kicker
  anchored to corners (see 7.2).

### 7.2 Shared furniture (all templates, this is the recognizable signature)

- Parchment background `#f7f1e6`.
- **Wordmark + fox lockup** (Fraunces "Ruby Lore" + `fox.svg`), small, **top-left
  corner** inside the safe area. Verify the fox reads at ~40–64px, its face
  fill `#faf4ea` is near-parchment, so use a version with an ink/garnet outline
  for the lockup if the plain mark turns muddy at that size.
- **Type "plaque"/kicker**, small caps, in **brass-text `#7a5e34`** (5.4:1,
  passes AA), e.g. `PERSON`, `GLOSSARY`, `TIMELINE · 2020`, `TALK`, `STORY`.
- **Title** in Fraunces, garnet `#9b1b30` (7.2:1 on parchment), the hero.
- **Supporting line** in Literata, ink/soft.
- Small garnet ruby-lozenge motif (`--gem`), bottom-right corner accent.

The invariant furniture (parchment + garnet Fraunces title + fox lockup + ruby
lozenge + ink frame) is what makes every image instantly *Ruby Lore*. Per-type
differentiation is intentionally light (the kicker word, optionally a single
per-type accent hue from the existing palette) rather than five bespoke layouts.

### 7.3 Type sizing & fitting (grounded in the real corpus)

- **Title:** auto-fit **min ~54px / max ~96px** at the 1200 canvas (so it
  survives the ~0.3× downscale Slack/mobile feeds apply), wrapping to **at most 3
  lines**.
- **Supporting line:** Literata **min ~30–32px**, at most **2 lines**, truncated
  on a **word boundary** with an ellipsis.
- **Real worst case to test in Phase 1:** the longest title is
  **`"How to build a blog in 15 minutes with Rails" (DHH, 2005)` (~57–60 chars,
  `src/_cards/talks/fifteen-minute-blog.md`)**, more than double the
  `Yukihiro "Matz" Matsumoto` / `"Wat" (Gary Bernhardt, 2012)` cases. Other
  awkward ones: `David Heinemeier Hansson (DHH)`,
  `Aaron Patterson ("tenderlove")`. The longest hook is `rails-from-basecamp`
  (~103 chars, two sentences), a 2-line truncation strands the second sentence,
  which is fine because the **hook is optional garnish; the title carries the
  card**. Prefer `summary` when present (none exist today, add a synthetic
  `summary` card to the Phase-2 tests), else `hook`.
- **Overflow floor:** if a title can't fit in 3 lines at min size, drop the
  supporting line first to buy the title room, then hard-truncate the title with
  an ellipsis. Define this so overflow is impossible.
- **Empty supporting text:** if neither `summary` nor `hook` exists, recenter the
  title block vertically (no dangling ellipsis or empty gap).

### 7.4 Fonts

satori needs `ttf`/`otf`/`woff` (not `woff2`). **Use static, non-variable
faces**, not the `@fontsource-variable/*` packages the site ships, selecting a
static weight from a *variable* face in satori often renders the default
instance, not the requested weight. Either depend on the static `@fontsource/*`
packages or **vendor static ttf into `script/og/fonts/`** (committed). Pick
explicit weights (e.g. Fraunces 600, Literata 400/600) and validate in Phase 1.
Font licensing (OFL) already permits embedding (license files are committed).
Pin the font packages **exactly** and include the ttf bytes in the content hash
(§8) so a font bump invalidates cached images.

### 7.5 Per-type accents

- `person`: title = name; kicker `PERSON`.
- `vocabulary`: kicker `GLOSSARY`; title = term.
- `release`: kicker `TIMELINE · <year>`, where `<year>` is the **earliest**
  `dates` entry (matching `json_ld.rb#earliest_date` / `timeline.erb`); if a
  release has **no** `dates`, drop the ` · <year>` suffix (just `TIMELINE`).
  Year-only sidesteps `precision`.
- `talk`: kicker `TALK`. `story`: kicker `STORY`.
- Section pages: a section template using the section title + a one-line
  descriptor sourced from an explicit builder map (or an `og_descriptor` front
  matter key), section pages have no `hook`.

### 7.6 Fallback consistency

`og-share.png` (the default) should be visually consistent with this system so
untemplated pages don't look off-brand next to templated ones. If it isn't
already parchment/garnet, align it in Phase 4 (not a redesign, just brand
consistency). Note the existing `og-share.png` is ~313 KB (relevant to §8's size
budget).

## 8. Performance, caching, determinism

- **Batch, don't spawn-per-image.** One Node process renders the whole manifest
  (Phase B).
- **Content hash (per-image, drives the filename and the renderer skip).** Hash
  over: title, kicker, supporting text, kind/type, **the resolved `satori` and
  `@resvg/resvg-js` versions**, a **hash of `render.mjs` + the template source**,
  and the **font file bytes**. Including the renderer versions + template source
  means `template_version` is **auto-derived** (no manual constant to forget);
  bumping satori/resvg or editing the layout invalidates every image, so an
  upgrade can't silently serve old-renderer bytes mixed with new.
- **CI cache (`actions/cache`, workflow-level).** This is a *different* layer
  from the per-image hash. Cache the **`tmp/og-cache/` directory** with a broad
  key **plus `restore-keys`** for partial restore, e.g.
  `key: og-cache-${{ hashFiles('src/**','script/og/**','package-lock.json') }}`,
  `restore-keys: og-cache-`. Without `restore-keys`, any content change busts the
  whole blob and every image re-renders.
- **Orphan pruning (required).** Content-hash filenames mean edits create new
  files and never remove old ones; deleted/renamed pages leave orphans. After
  building the manifest, **delete any `tmp/og-cache/` PNG not referenced by the
  current manifest, before the cache is saved**, so the cached blob doesn't grow
  unbounded across every PR/push/scheduled run.
- **Determinism is per-platform.** `@resvg/resvg-js` is a napi native binary
  shipped as platform-specific optional deps; same-version + same-platform is
  byte-stable, but linux-x64 (CI) and a local macOS/arm64 machine run different
  compiled binaries and are **not** guaranteed byte-identical. Therefore: pin
  **exact** versions of `satori` and `@resvg/resvg-js` in `package.json`
  (`package-lock.json` + `npm ci` then locks the platform binary set); scope the
  golden snapshot (§9) and the "unchanged page ⇒ byte diff is a regression" rule
  to **linux-x64 only**.
- **`scheduled-build.yml` must cold-render.** That workflow exists to surface
  build/dependency rot, so it must **not** restore the OG cache (or must
  force-render), otherwise the Node/satori/resvg/native-binary path is skipped
  and its rot goes undetected.
- **Two-build cost + byte-for-byte guarantee.** `ci.yml` validates and `pages.yml`
  rebuilds; OG generation makes the double build costlier *and* puts the
  "deployed bytes == validated bytes" claim at the mercy of render determinism.
  **Recommended:** have `ci.yml` upload `output/` as an artifact and `pages.yml`
  **download and deploy it** instead of rebuilding, this eliminates the double
  render cost and makes byte-for-byte literally true. (Fallback if we keep two
  builds: rely on the pinned-version per-platform determinism + a shared cache,
  and accept the small risk.) This is a deploy-topology change, see §13 Q.
- **Budgets.** JS bundle-size gate is **JS-only and unaffected** (verified:
  `check_bundle_size.rb` reads only the two JS entry points). Add a per-image
  PNG size check in `check_og.rb`; set the threshold **above the existing
  ~313 KB `og-share.png`** (e.g. hard-fail > 400 KB, warn > 300 KB) so the
  shipped default doesn't trip it. Cold render of ~20 pages is expected to be a
  few seconds.
- **Local dev now requires Node.** `bundle exec bridgetown build` now shells out
  to `node`, so a bare build without a prior `npm ci` fails; the builder must
  fail with an actionable message, and `docs/runbook-unrot.md`'s local-repro
  chain must note the `npm ci` prerequisite. Keep satori/resvg in
  `devDependencies` and never set `NODE_ENV=production`/`--omit=dev` (CI uses
  `BRIDGETOWN_ENV`, not `NODE_ENV`, so devDeps install).

## 9. Testing & validation

**html-proofer does NOT and cannot (as invoked) validate `og:image`**, its
OpenGraph check is opt-in and not enabled, and `og:image` is absolute while CI
runs `--disable-external`. So the OG gate is entirely `check_og.rb`; the "images
exist before html-proofer" argument buys nothing for OG and is dropped.

- **New Ruby gate `script/check_og.rb`** (mirrors existing `check_*.rb`, runs
  under `bundle exec` after `bridgetown build`, **introduced in Phase 1**):
  1. For every rendered HTML page in `output/`, `og:image`/`twitter:image` are
     present, absolute, and **resolve to an existing local file** in `output/`
     (the gate maps the absolute URL back to the local path itself, html-proofer
     won't); the file is a valid `1200×630` PNG (read the PNG header);
     `og:image:width/height/type` and `og:image:alt` are present and consistent.
  2. **Uniqueness / anti-silent-failure:** every **templated** page points at a
     **distinct** `/og/**` image, and **no templated page points at
     `og-share.png`**. (Because the fallback file always exists, a wholesale
     renderer failure would otherwise pass criterion 1 silently, this catches
     it. Combine with the renderer's non-zero exit, but verify independently.)
  3. **JSON-LD image consistency is asserted on card pages only** (the only
     pages with an image-bearing node); on card pages the JSON-LD `ImageObject`
     url equals `og:image`.
- **html-proofer** stays as-is for internal links/images (unchanged).
- **Golden snapshot** of representative images, include **`matz`** and
  **`why-the-lucky-stiff`** (R31), plus a plain-Ruby unit assertion that the
  `why-the-lucky-stiff` manifest entry contains exactly `{title, hook, kicker}`
  and **no `sources`/`aka`/body**, and that its alt equals the exact curated
  value. Snapshots are validated on **linux-x64 only** (§8). Assert the PNG has
  no timestamp/metadata chunk so a future resvg change is caught.
- **Manual preview matrix** before merge (real preview URLs): X, Slack, Discord,
  iMessage, LinkedIn Post Inspector, Facebook Sharing Debugger, **WhatsApp**,
  **Telegram**, Mastodon, and `opengraph.xyz` / `metatags.io`. Spot-check one
  page of each type. (WhatsApp/Telegram have their own scrapers; WhatsApp only
  shows the *large* preview under ~300 KB, the §8 budget rationale.)
- **Accessibility:** confirm `alt` is meaningful, entity-first, and R31-safe.

## 10. Content & safety constraints

- **R31 (_why anonymity), tightened invariant.** The protective rule is not
  merely "inputs are card front matter" (`sources`/`aka` *are* front matter). It
  is: **the image and its alt text expose only `title` + `hook`
  (supporting line) + `kicker`, never `sources`/`aka`/`identity_urls`/body, and
  the renderer performs no external lookup.** For `why-the-lucky-stiff`
  (`title: "_why the lucky stiff"`, `hook: "The artist who made Ruby feel like
  play, then vanished."`) that is safe: the slug/filename is the pseudonym, the
  kicker is `PERSON`, and alt uses title+kicker only. Enforced by the §9 golden
  snapshot + manifest-shape assertion so a future template that tried to surface
  `sources`/`aka` would fail the gate.
- **Escaping.** The real corpus has **no non-ASCII** anywhere; the actual
  escaping concern is **embedded straight double-quotes**
  (`Yukihiro "Matz" Matsumoto`, `"Optimize for programmer happiness"`,
  `"Wat" (Gary Bernhardt, 2012)`, etc.). Text is passed to satori as **data**
  (not interpolated markup) and into meta attributes via auto-escaping ERB
  `<%= %>`. Tests use a real quoted title plus a **synthetic** non-ASCII title
  (don't claim non-ASCII exists in the corpus when it doesn't).
- **License.** Content CC BY 4.0, fonts OFL, both already permit this use; no
  new third-party dependency ships to the site (renderer is build-time only).

## 11. Phased rollout

- **Phase 0, this spec.** Approved before any code.
- **Phase 1, pipeline skeleton + real gate (risk-retiring).** Add satori/resvg
  (pinned exact) + static fonts, the Node renderer, the two-hook Bridgetown
  builder, the `resource.data.og_image` metadata refactor (so `_head.erb` +
  `json_ld.rb` read one absolute value), and **`check_og.rb` including the
  uniqueness check**. Ship **one default template** that reproduces the current
  look for all selected pages. Prove: the pre-render/post-write split, cache in
  `tmp/og-cache/` + orphan prune, `actions/cache` + `restore-keys`, per-platform
  determinism, the longest-title (`fifteen-minute-blog`) + synthetic-overflow
  fitting, and CI. **No visible per-page variation yet.**
- **Phase 2, card templates.** Per-type card images (person/story/talk/
  vocabulary/release) with title + supporting text + kicker; `article:*` tags;
  JSON-LD `ImageObject` + `Organization.logo`; golden snapshots (incl.
  `why-the-lucky-stiff`) + synthetic `summary`/quoted-title/no-hook tests. The
  shareability payoff.
- **Phase 3, section pages.** Templates for home/people/stories/talks/glossary/
  timeline/start-here (credits, 404, 500 stay on the default).
- **Phase 4, polish & QA.** Full preview matrix, per-image size budget,
  `og-share.png` brand-consistency check, typography refinements, and docs (a
  `docs/` note on the OG pipeline + the `npm ci` prerequisite in
  `runbook-unrot.md`).

Each phase leaves the site correct (the CI gate + fallback guarantee mean no
broken image ships at any phase).

## 12. Risks & mitigations

| Risk | Mitigation |
| --- | --- |
| Bridgetown `cleanup` deletes mid-build PNGs | Write bytes in `hook :site, :post_write`; assign metadata in `:pre_render`. (§5.1) |
| Cache defeated by the cleaner / grows unbounded | Cache in `tmp/og-cache/` (not `output/`); prune orphans before save; `restore-keys`. (§8) |
| Cross-arch byte drift (resvg native binary) | Scope byte-stability to linux-x64; pin exact versions; golden snapshot on CI platform only. (§8) |
| satori variable-font wrong-weight rendering | Use static ttf faces, not variable; validate weights in Phase 1. (§7.4) |
| Upgrade serves stale cached bytes | Content hash includes resolved renderer versions + template/render source. (§8) |
| Silent wholesale renderer failure masked by fallback | `check_og.rb` asserts per-page uniqueness + no templated page on the default; renderer non-zero exit. (§9) |
| `check_og.rb` unsatisfiable on non-card / extra-type pages | Scope JSON-LD-image assertion to card Article pages; untemplated types take the default. (§6, §9, §13) |
| Relative `og:image` rejected by scrapers | Store absolute URL once on `resource.data.og_image`. (§5.2) |
| Node↔Ruby handoff fragile | Single batch shell-out with JSON manifest; non-zero exit fails build; ERB independent of it; Option C fallback. (§4) |
| Social platform caches old image | Content-hash filenames change the URL on content change. (§5.2) |
| R31 regression | Image/alt expose only title+hook+kicker; golden + manifest-shape gate. (§10) |
| scheduled-build hides rot via warm cache | scheduled-build cold-renders. (§8) |
| Local build fails without `npm ci` | Actionable error + runbook note. (§8) |

## 13. Open questions (for the approver)

1. **Deploy topology (§8):** approve having `pages.yml` deploy `ci.yml`'s
   uploaded `output/` artifact (eliminates the double render, makes byte-for-byte
   literal), or keep two independent builds relying on pinned-version
   determinism? *Recommendation: share the artifact.*
2. **Extra allowed types (`artifact/institution/book/program`):** none exist
   today and none are in `PER_TYPE_SCHEMA`/`TYPE_SEGMENTS`. Confirm they should
   **fall back to the default image** (and a generic kicker) until a template +
   schema mapping is added, rather than get a template now. *Recommendation:
   default fallback.*
3. **Section-page coverage:** template all section pages (Phase 3) and leave
   credits/404/500 on the default forever? *Recommendation: yes.*
4. **`Organization.logo` raster:** OK to add a committed `src/images/logo-512.png`
   (raster fox mark) for the structured-data logo? *Recommendation: yes, it's
   an independent SEO win.*
5. **Design confirmation:** one canonical parchment look with an ink hairline
   edge (no dark variant), kicker in brass-text `#7a5e34`, title garnet, all
   confirmed?
```
