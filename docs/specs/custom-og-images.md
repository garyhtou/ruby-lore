# Spec & Plan: Custom per-page Open Graph images

Status: **Draft for review** · Owner: Gary Tou · Target branch: `claude/custom-og-images-spec-fnb6vu`

> This is a spec and implementation plan only. No feature code ships until this
> document is approved.

## 1. Summary

Ruby Lore currently serves one site-wide social share image
(`src/images/og-share.png`, 1200×630) for every page. This spec proposes
generating a **unique, on-brand Open Graph / Twitter image per page at build
time**, so that every card (people, stories, talks, glossary terms, timeline
releases) and every section page gets a share image bearing its own title and
hook. The default image remains as a fallback and for pages we don't template.

The work is scoped to **image generation + metadata wiring**; it does not change
site content or routing.

## 2. Motivation & goals

Ruby Lore's stated goals are SEO, "AI SEO", and shareability. Per-page images
serve all three:

- **Shareability (primary).** A link to `/people/matz/` unfurled in Slack,
  Discord, iMessage, X, LinkedIn, or Mastodon currently shows the same generic
  card as the home page. A title-bearing, branded card dramatically increases
  click-through and makes shares self-describing. This is the single biggest win.
- **SEO.** `og:image` is not a Google ranking factor, but rich, correct social
  cards increase referral traffic and dwell, and Discord/Slack/X previews are a
  real discovery surface for a niche history site. Correct `og:image:width`/
  `height`/`alt` also removes preview-render warnings in social debuggers.
- **AI SEO.** LLM crawlers read text and structured data far more than images,
  so the honest, high-leverage AI-SEO wins here are: (a) keeping the per-page
  JSON-LD `image` in sync with the real per-page image (today `json_ld.rb`
  hardcodes the site-wide image, see §6), and (b) descriptive `og:image:alt`
  text that restates the page's entity/title. We explicitly do **not** claim
  images meaningfully move AI answer-engine ranking; the JSON-LD/alt-text
  hygiene is the part that does.

### Success criteria

1. Every templated page emits a `1200×630` PNG `og:image` unique to that page.
2. `og:image`, `twitter:image`, JSON-LD `image`, `og:image:width/height`, and
   `og:image:alt` are all present and mutually consistent.
3. Cards without a template (or any future page) fall back cleanly to the
   existing `og-share.png`, never a broken image.
4. Images render correctly in the social-preview matrix (§9).
5. The build stays deterministic and reproducible (same input → same bytes),
   and the added build time is bounded and cached.
6. No regression to existing CI gates (html-proofer, bundle-size, zero-JS
   content, JSON-LD validity).
7. The `_why` anonymity constraint (R31) is preserved (§10).

### Non-goals

- Runtime/on-demand image generation (impossible on our host, see §4).
- Animated, video, or per-viewer-personalized images.
- Light/dark *variants* of the share image (social platforms don't send a color
  scheme; we ship one canonical look, see §7).
- Redesigning the existing default `og-share.png`.

## 3. Current state (grounded in the codebase)

- **Generator:** Bridgetown 2.2, ERB templates, `template_engine: erb`
  (`bridgetown.config.yml`). Cards are a collection rendered with the `card`
  layout.
- **OG wiring today:** `src/_partials/_head.erb` computes a single
  `share_image_url = "#{site.config.url}/images/og-share.png"` and emits
  `og:image` + `twitter:image` from it. It already computes per-page
  `og_title`, `page_description` (summary → hook → site description), `og_type`
  (`article` for cards, else `website`), and `page_url`. A code comment there
  explicitly flags per-page images as "a later, optional enhancement."
- **JSON-LD:** `src/_components/json_ld.rb` has its **own** `share_image_url`
  helper (duplicated, same value) used for each card's `Article.image`. Its
  comment says: "if per-page OG images ever land, update both call sites." This
  spec is that moment.
- **Card model:** front matter carries `type`, `title`, `hook`, optional
  `summary`, `dates`, `sources` (see `lib/slugs.rb`, `script/validate.rb`).
  Types in routing: `person`→people, `story`→stories, `talk`→talks,
  `vocabulary`→glossary, `release`→timeline (`Slugs::TYPE_SEGMENTS`). Validator
  also allows `artifact, institution, book, program`.
- **Section/standalone pages:** `index`, `timeline`, `glossary`, `people`,
  `stories`, `talks`, `start-here`, `credits`, `404`, `500`.
- **Brand tokens** (`frontend/styles/tokens.css`): parchment `#f7f1e6`, ink
  `#241f1c`, garnet `#9b1b30` / deep `#7a1526`, fox `#d2662a`, brass `#b08d57`.
  Fonts: **Fraunces** (display), **Literata** (body), **JetBrains Mono**
  (self-hosted woff2 in `src/fonts/`). Fox mark: `src/images/fox.svg`.
- **Build/deploy:** `.github/workflows/ci.yml` builds with `npm ci` →
  `npm run esbuild` → `bundle exec bridgetown build`, then runs gates:
  `validate.rb`, `check_bundle_size.rb`, `check_no_js_content.rb`,
  `check_json_ld.rb`, and **html-proofer over `output/`** (verifies every
  referenced image exists). `pages.yml` deploys `output/` to GitHub Pages after
  CI passes. `scheduled-build.yml` rebuilds periodically. Both Ruby 4.0 and
  Node 22 are available in CI. `BRIDGETOWN_ENV=production` for the canonical
  build.

**Hard constraint:** `chunkybacon.dev` is GitHub Pages, DNS-only (not
Cloudflare-proxied, see `docs/deploy.md`), so there is **no server or edge
worker** in the request path. All image generation must happen **at build
time**.

## 4. Approach options

| Option | How | Verdict |
| --- | --- | --- |
| **A. Satori + resvg (build-time, JS)** | Render an HTML/JSX-ish template → SVG (`satori`) → PNG (`@resvg/resvg-js`). Runs in Node, no browser. | **Recommended.** |
| B. Headless Chromium (Playwright/Puppeteer) | Render a real HTML page per image and screenshot it. | Rejected: heavier CI, and screenshot bytes vary by platform/font hinting, breaking "byte-for-byte what CI validated." |
| C. Ruby-native (SVG template → resvg/librsvg, or ImageMagick composite) | Build an SVG per page in a Ruby builder and rasterize. | Viable fallback; rejected as primary because SVG has no text auto-wrap (manual line-breaking) and it's more bespoke than the well-trodden satori path. |
| D. Hand-designed static images per page | Design each in Figma, commit PNGs. | Rejected: doesn't scale, drifts from content, no automation. |

### Why Option A

- **No runtime host needed**, pure build step, fits GitHub Pages.
- **Deterministic**, satori + resvg produce stable bytes across platforms far
  better than a headless browser, satisfying the repo's reproducibility ethic.
- **Fits the existing toolchain**, Node 22 + npm are already first-class in CI
  (`esbuild`). This is the Vercel-OG lineage; well-documented, actively
  maintained.
- **Fast**, hundreds of images/sec, no browser boot.
- **Real font control**, we embed our own Fraunces/Literata (see §7 note on
  woff2 → ttf).

## 5. Recommended architecture

### 5.1 Generation model

A small **Node renderer** produces PNGs from a **manifest** of page descriptors,
and a **Bridgetown builder** produces that manifest and wires the metadata, so
that a single `bin/bridgetown build` (local *and* CI) yields identical output.

```
bridgetown build
  └─ plugins/builders/og_images.rb   (Ruby, runs during build)
       1. walks resources (cards + templated section pages)
       2. builds an OG model per page: {slug, type, title, hook/summary,
          kicker, out_path, content_hash}
       3. writes tmp/og-manifest.json
       4. shells out ONCE: node script/og/render.mjs tmp/og-manifest.json
            - batch render (one process, not one-per-image)
            - skips any entry whose content_hash matches a cached PNG
            - writes PNGs into output/og/<type>/<slug>-<hash>.png
       5. exposes each page's og image path to templates (via a data map
          the head partial reads)
```

The head partial (`_head.erb`) and `json_ld.rb` then read the per-page image
path, falling back to `og-share.png` when a page has no generated image.

> **Integration detail to validate in Phase 1:** the cleanest way to hand the
> builder-computed image path back to `_head.erb`. Candidate mechanisms, in
> order of preference: (a) store it on `resource.data` (e.g.
> `resource.data.og_image`) from a `Builder` hook that runs *before* render;
> (b) a site-wide `site.data`/registry keyed by slug the partial looks up; (c)
> derive the path deterministically in the partial from the same inputs
> (type+slug+content-hash) the builder used. Phase 1 picks one; (a) is
> preferred because it keeps the partial dumb.

### 5.2 Filenames & URLs

- Path: `/og/<type>/<slug>-<hash8>.png` (e.g.
  `/og/people/matz-a1b2c3d4.png`), where `<hash8>` is the first 8 hex chars of
  a content hash over the exact inputs that determine the pixels (title, hook,
  kicker, type, template version, font files, see §8).
- The **content hash in the filename is deliberate**: social platforms cache
  `og:image` URLs aggressively, so when a page's title/hook changes the URL
  changes and unfurls refresh. It also gives us a natural build cache key.
- Section pages use a synthetic type segment, e.g. `/og/pages/home-….png`.

### 5.3 Output, not committed to git

Images are generated into `output/` during the build and are **not** committed
(consistent with `output/` being the build artifact; avoids binary churn and
keeps git-derived `lastmod` clean). Reproducibility is guaranteed by the
deterministic renderer; build speed is protected by a CI cache (§8).

## 6. Metadata wiring

In `src/_partials/_head.erb`, replace the single `share_image_url` with a
per-page value (generated image if present, else `og-share.png`) and add the
supporting tags:

```erb
<meta property="og:image" content="<%= og_image_url %>" />
<meta property="og:image:width" content="1200" />
<meta property="og:image:height" content="630" />
<meta property="og:image:type" content="image/png" />
<meta property="og:image:alt" content="<%= og_image_alt %>" />
<meta name="twitter:image" content="<%= og_image_url %>" />
<meta name="twitter:image:alt" content="<%= og_image_alt %>" />
```

- `og_image_alt`: a short, descriptive sentence, e.g.
  `"Ruby Lore, <title>"` plus the kicker, restating the page entity for
  screen readers and AI crawlers. Never the raw hook if it risks R31 (§10).
- **`json_ld.rb`:** replace the local `share_image_url` helper so each card's
  `Article.image` (and any other node currently using it) points at that page's
  generated image, keeping structured data and OG tags in sync. Prefer a single
  shared source of truth for "this page's image URL" so the two call sites the
  code comments warn about can never drift again.
- Keep `og:url`/canonical logic exactly as-is (the existing trailing-slash
  guard is correct).

## 7. Image design

**Canvas:** 1200×630, PNG, one canonical light look (parchment ground). Museum
/ archival-plaque aesthetic matching the site.

**Shared furniture (all templates):**
- Parchment background `#f7f1e6` with a subtle brass hairline frame.
- Ruby Lore wordmark (Fraunces) + fox mark (`fox.svg`) lockup, small, a corner.
- A **type "plaque"/kicker** in brass (`#b08d57`), small caps, e.g. "PERSON",
  "GLOSSARY", "TIMELINE · 2020", "TALK", mirroring the on-site breadcrumb
  vocabulary (`Slugs::TYPE_SEGMENTS`).
- The **title** in Fraunces, large, garnet `#9b1b30`, auto-fit to 1–3 lines.
- A **supporting line** (hook or summary) in Literata, ink/soft, truncated to
  ~2 lines with an ellipsis.
- A small garnet ruby-lozenge motif (the site's `--gem` ornament).

**Per-type accents** (subtle, not a redesign per type):
- `person`: title = person's name; kicker "PERSON".
- `vocabulary`: kicker "GLOSSARY"; title = the term.
- `release`: kicker "TIMELINE · <year>" (from `dates`); title = release name.
- `talk`: kicker "TALK".
- `story`: kicker "STORY".
- Section pages (home, people, stories, talks, glossary, timeline, start-here):
  a section template using the section title + a one-line descriptor.

**Fonts:** satori needs `ttf`/`otf`/`woff` (not `woff2`). We already depend on
the `@fontsource-variable/*` packages; the renderer will load the **ttf** faces
from `node_modules/@fontsource-variable/*/files/*.ttf` (or a checked-in
`script/og/fonts/` copy), so the images use the real brand fonts. Instantiate
the needed weights (variable-font handling in satori is limited; we pick static
weights, e.g. Fraunces 600, Literata 400/600, and validate rendering in
Phase 1). Font licensing (OFL) already permits embedding; license files are
already committed under `src/fonts/`.

**Text fitting:** longest real titles (e.g. `Yukihiro "Matz" Matsumoto`,
`"Wat" (Gary Bernhardt, 2012)`) must fit, the template auto-shrinks the title
font within a min/max range and wraps to at most 3 lines, then the supporting
line truncates. Phase 1 tests against the longest existing title + a synthetic
overflow case.

## 8. Performance, caching, determinism

- **Batch, don't spawn-per-image.** One Node process renders the whole manifest.
- **Content-hash cache.** Skip regenerating a PNG whose `<hash>` already exists.
  The hash covers: title, kicker, hook/summary, type, **template version**
  (a constant bumped when the design changes to force a global re-render), and a
  hash of the font files. In CI, persist `tmp/og-cache/` (or the emitted
  `output/og/`) via `actions/cache` keyed on that content so unchanged pages
  cost ~0 across builds and the `scheduled-build` workflow.
- **Determinism.** satori + resvg with pinned versions and pinned fonts produce
  stable bytes. Pin exact versions in `package.json`; treat a bytes-changed
  diff on an unchanged page as a regression to investigate.
- **Budget.** ~20 pages today; full cold render is expected to be a few seconds.
  Add a soft budget/log line; the images are static assets, so the existing JS
  **bundle-size gate is unaffected** (it measures JS only). Add a per-image PNG
  size sanity check (e.g. warn > 300 KB).
- **CI ordering.** OG generation happens *inside* `bridgetown build`, so images
  exist in `output/` before html-proofer runs and are covered by its existing
  image-existence check.

## 9. Testing & validation

- **New Ruby gate `script/check_og.rb`** (mirrors the existing `check_*.rb`
  pattern, runs under `bundle exec` in CI): for every rendered HTML page in
  `output/`, assert `og:image` resolves to an existing file, is `1200×630`
  (read PNG header), and that `og:image:alt`, `og:image:width/height`, and the
  JSON-LD `image` are present and consistent with the `og:image`.
- **html-proofer** already fails on any missing referenced image, kept.
- **Golden snapshot** of one representative image (e.g. `matz`) to catch
  accidental visual/byte drift; regenerate intentionally when the template
  version bumps.
- **Manual preview matrix** before merge, using the real deployed/preview URLs:
  X (Twitter Card validator or post preview), Slack, Discord, iMessage,
  LinkedIn Post Inspector, Facebook Sharing Debugger, Mastodon, and
  `opengraph.xyz` / `metatags.io`. Spot-check one page of each type.
- **Accessibility:** confirm `alt` text is meaningful and R31-safe.

## 10. Content & safety constraints

- **R31 (_why anonymity).** The `why-the-lucky-stiff` card deliberately omits
  identifying info; its OG image must use **only** that card's own front matter
  (`title`, `hook`), which is already curated to be name-respectful. The
  renderer must **never** pull from any external identity source, and `alt`
  text must not add identifying detail. This is naturally satisfied because the
  builder's only inputs are card front matter, call it out in code + tests so a
  future change can't regress it.
- **Escaping.** Titles/hooks contain quotes, em-dashes, and non-ASCII (e.g.
  `Yukihiro "Matz" Matsumoto`). Text is passed as data to satori (not
  interpolated into markup) and into meta attributes via normal ERB escaping;
  add a test with a quote-and-non-ASCII title.
- **License.** Content is CC BY 4.0, fonts OFL, both already permit this use;
  no new third-party runtime dependency is added to the shipped site (renderer
  is build-time only).

## 11. Phased rollout

- **Phase 0, this spec.** Approved before any code.
- **Phase 1, pipeline skeleton.** Add satori/resvg deps (pinned), the Node
  renderer, the Bridgetown builder, and the metadata-source refactor so
  `_head.erb` + `json_ld.rb` read one per-page image value. Ship **one default
  template** that reproduces the current look for *all* pages, prove
  determinism + caching + CI + the `_head.erb` handoff mechanism (§5.1). Keep
  `og-share.png` as fallback. **Risk-retiring phase, no visible per-page
  variation yet.**
- **Phase 2, card templates.** Per-type card images (person, story, talk,
  vocabulary, release) pulling title + hook/summary + kicker. Add
  `og:image:alt`, dimensions, and JSON-LD per-page image sync. Add
  `check_og.rb` + golden snapshot. This is the shareability payoff.
- **Phase 3, section pages.** Templates for home, people, stories, talks,
  glossary, timeline, start-here (credits/404/500 keep the default).
- **Phase 4, polish & QA.** Full preview matrix, per-image size budget, docs
  (`docs/` note on the OG pipeline), and any typography fitting refinements.

Each phase is independently shippable and leaves the site in a correct state
(fallback guarantees no broken images at any point).

## 12. Risks & mitigations

| Risk | Mitigation |
| --- | --- |
| satori variable-font / CSS-subset quirks | Use static weights; validate the real longest titles in Phase 1 before committing to the design. |
| Non-deterministic bytes across CI vs local | Pin satori/resvg versions + fonts; golden snapshot; investigate any unchanged-page byte diff. |
| Build-time cost grows with content | Content-hash cache + CI cache; batch render; cold render is still seconds for the foreseeable card count. |
| Node↔Ruby handoff during `bridgetown build` fragile | Batch single shell-out with a JSON manifest and non-zero exit on failure; Phase 1 proves it; documented fallback is Option C (Ruby+resvg) if the boundary proves painful. |
| Social platform caches an old image | Content-hash filenames change the URL when content changes, forcing re-unfurl. |
| R31 regression | Inputs limited to card front matter; explicit test + code comment. |
| html-proofer / gates break | Generate into `output/` before gates run; add `check_og.rb`; images don't affect the JS bundle gate. |

## 13. Open questions (for reviewers / approver)

1. **Renderer language:** confirm the Node (satori) path vs. staying Ruby-only
   (Option C). Recommendation: Node/satori.
2. **Commit images vs. build-only:** recommendation is build-only into
   `output/`. Acceptable, or do you want them committed for inspectability?
3. **Section-page coverage:** template all section pages (Phase 3) or leave
   low-traffic ones (credits, error pages) on the default forever?
4. **Design fidelity:** one canonical parchment look confirmed (no dark
   variant)?
5. **`_head.erb` handoff:** approve `resource.data.og_image` as the mechanism,
   or prefer a deterministic path derived in the partial?
```
