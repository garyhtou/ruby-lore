# Un-rot the build

A runbook for reviving Ruby Lore's build after it's gone stale: a red
run on [`scheduled-build.yml`](../.github/workflows/scheduled-build.yml)
(the monthly rot check), a red PR on
[`ci.yml`](../.github/workflows/ci.yml) that isn't about your change, or
just "I haven't touched this repo in a year and `bundle install` is
yelling at me."

You do not need to have built this site before to follow this. Work
through the sections in order; most rot is fixed by the first two or
three steps.

## 0. Orient yourself

- The site is a [Bridgetown](https://www.bridgetownrb.com/) static
  site. Ruby builds it, esbuild bundles the frontend JS.
- **The canonical/production build is `BRIDGETOWN_ENV=production bundle
  exec bridgetown build`** - that's what both `ci.yml` and
  `scheduled-build.yml` run (set job-wide via `env:`), and it's what
  should be deployed. A bare `bundle exec bridgetown build` (no
  `BRIDGETOWN_ENV`) defaults to Bridgetown's **development** environment,
  which is fine for local preview but ships `live_reload_dev_js`'s
  dev-mode EventSource in the HTML - real users' browsers would then
  repeatedly retry a nonexistent livereload endpoint. Don't deploy a dev
  build.
- Pinned versions live in `.ruby-version` (Ruby) and `.nvmrc` (Node),
  and are echoed in both `.github/workflows/ci.yml` and
  `.github/workflows/scheduled-build.yml`.
- The full "is this repo healthy" gate chain is defined in
  `.github/workflows/ci.yml` and mirrored by
  `.github/workflows/scheduled-build.yml`. Reproducing that chain
  locally (Step 2 below) is the fastest way to see exactly what broke.

## 1. Pull latest and reinstall clean

Stale local state is the single most common cause of "it's broken" that
turns out to be nothing. Start here even if you're sure it's not this.

```sh
git pull origin main

# Ruby gems, matching the Gemfile.lock exactly (fails loudly if the
# lockfile and installed gems disagree, which is useful signal on its own)
bundle install

# Frontend deps, from a clean slate (npm ci, not npm install, so it
# respects package-lock.json exactly rather than quietly upgrading things)
npm ci
```

If either command fails outright (not a build error, an *install*
error), jump to Step 4 (bump gems) or Step 5 (bump the frontend) - the
lockfile is probably pointing at something that no longer resolves
(a yanked gem version, a deleted npm package version, etc).

## 2. Reproduce the failure locally

Run the same chain the CI/scheduled workflows run, in order, so you can
see exactly which step is red instead of guessing from an Actions log:

```sh
# 1. Content validation (schema, links, sources) - script/validate.rb
bundle exec ruby script/validate.rb

# 2. Frontend bundle (esbuild) - see Step 6 if this is what's broken
npm run esbuild

# 3. Bundle-size budget (stdlib only, no bundle exec needed)
ruby script/check_bundle_size.rb

# 4. The actual site build - BRIDGETOWN_ENV=production matches CI/what's
#    deployed (see Section 0); a bare `bundle exec bridgetown build`
#    builds dev mode instead (fine for local preview, not for the gate
#    chain below, since it ships live-reload cruft the guards don't check
#    for).
BRIDGETOWN_ENV=production bundle exec bridgetown build

# 5. Zero-JS-content guard (needs bundle exec: renders Markdown through
#    Kramdown, a bundled gem - see the comment in ci.yml for why this
#    bit people before)
bundle exec ruby script/check_no_js_content.rb

# 6. JSON-LD validity
bundle exec ruby script/check_json_ld.rb

# 7. Internal links + images (html-proofer)
bundle exec htmlproofer output --disable-external --no-enforce-https
```

Whichever step fails first tells you which section below to read.
Everything failing at once (e.g. `bundle exec` itself erroring) usually
means Step 4/5 below (gem/Node pin has drifted out from under you).

## 3. Read the error before reaching for a version bump

A surprising amount of "rot" is a real bug this repo's guard scripts
were built to catch, not stale dependencies:

- `script/validate.rb` failures are almost always a content problem
  (a card's front matter, a broken `[[wiki-link]]`, a missing
  `## Sources` section) - fix the content, don't touch dependencies.
- `script/check_no_js_content.rb` and `script/check_json_ld.rb` failing
  usually means someone (possibly you) changed template/content logic
  in a way that broke a guarantee those scripts enforce - read the
  script's comments, they explain exactly what invariant it's checking.

Only move on to bumping dependencies once you've ruled out an actual
content/logic bug.

## 4. Bump gems

If `bundle install`/`bundle exec bridgetown build` is the thing that's
broken (a gem no longer installs, or installs but the build errors),
the Ruby dependency graph has drifted:

```sh
# See what's outdated first
bundle outdated

# Bump everything (respecting version constraints in the Gemfile)
bundle update

# Or bump just the highest-risk gems individually, which is safer and
# easier to bisect if something breaks:
bundle update bridgetown
bundle update bridgetown-sitemap   # lastmod from git history
bundle update kramdown kramdown-parser-gfm  # Markdown rendering (card bodies)
bundle update html-proofer
```

After bumping, re-run the full chain in Step 2. If `bridgetown build`
or a guard script breaks in a new way, check that gem's CHANGELOG for
breaking changes between the old and new pinned version - `git diff
Gemfile.lock` shows exactly what moved.

Commit the updated `Gemfile.lock` alongside any code changes needed to
adapt to a breaking change.

## 5. Bump the frontend (npm)

If `npm ci`/`npm run esbuild` is what's broken:

```sh
npm outdated

# Bump within the ranges already declared in package.json
npm update

# Or bump a specific package past its current range (check the
# package's changelog for breaking changes first, especially for GSAP
# and esbuild - both ship breaking changes across major versions):
npm install esbuild@latest
npm install gsap@latest
```

`package.json`'s `dependencies` (`gsap`, the `@fontsource-variable/*`
self-hosted font packages) and `devDependencies` (`esbuild`, the
PostCSS toolchain) are the two things most likely to need bumping.
Commit the updated `package-lock.json`.

## 6. Restore the esbuild / `asset_path` wiring, if that's what broke

The frontend build has two esbuild entry points, wired together with
Bridgetown's `asset_path` helper. If a dependency bump breaks *this*
wiring specifically (rather than just failing to install), here's what
should exist and where:

- **`esbuild.config.js`** declares two entry points: the small,
  always-loaded `frontend/javascript/index.js`, and the lazily-loaded
  `frontend/javascript/experience.js` (GSAP + the easter eggs/timeline/
  _why scroll scenes - see the comment in `esbuild.config.js` for why
  it's a real entry point rather than a dynamic `import()`).
- **`src/_partials/_head.erb`** emits `<script src="<%= asset_path :js
  %>">` for the `index.js` bundle on every page load, plus a
  `data-experience-src="<%= asset_path "javascript/experience.js" %>"`
  attribute carrying the built URL of the *second* bundle.
- **`frontend/javascript/core/load-experience.js`** reads that
  `data-experience-src` attribute off the script tag and injects the
  experience bundle as a plain `<script>` once idle/interaction fires
  (not on initial load - that's the whole point of the split, see
  for the performance reasoning).

If a Bridgetown or esbuild bump changes how `asset_path` resolves
files, or changes the manifest format that maps source entry points to
hashed output filenames, this is the chain to check: does
`esbuild.config.js` still list both entry points? Does `asset_path` in
`_head.erb` still resolve both `:js` and the literal
`"javascript/experience.js"` path to real hashed files under
`output/_bridgetown/static/`? Does `load-experience.js` still find the
`data-experience-src` attribute on the script tag it expects (check its
selector against the actual tag `_head.erb` renders)?

## 7. Bump Node/Ruby pins

Both CI workflows read pinned versions from repo files, not literal
numbers in the workflow YAML - so bumping the runtime is two files, not
one:

- **Ruby**: edit `.ruby-version` at the repo root (currently `4.0.6`).
  `ruby/setup-ruby` in both workflows auto-detects this file - no
  workflow YAML change needed for the Ruby version itself.
- **Node**: edit `.nvmrc` at the repo root (currently `22.23.1`).
  `actions/setup-node` in both workflows reads
  `node-version-file: ".nvmrc"` - again, no workflow YAML change needed.

After bumping either, run the full chain in Step 2 locally with the new
version installed (`rbenv`/`rvm`/`asdf` for Ruby, `nvm use` for Node) to
confirm nothing broke before pushing.

## 8. Refresh the pinned GitHub Action SHAs

Both `.github/workflows/ci.yml` and
`.github/workflows/scheduled-build.yml` pin every `uses:` action to a
commit SHA (not a floating tag), with the human-readable version as a
trailing comment, e.g.:

```yaml
uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
```

To bump one of these (e.g. picking up a new `actions/checkout`
release):

1. Find the new release tag on the action's GitHub repo (e.g.
   `github.com/actions/checkout/releases`).
2. Resolve that tag to its commit SHA (the release page links to it, or
   `git ls-remote --tags https://github.com/actions/checkout` locally).
3. Update the SHA **and** the trailing version comment together in
   **both** workflow files - `scheduled-build.yml` intentionally reuses
   the exact same pinned SHAs as `ci.yml` so the two workflows build
   with identical tooling. Don't let them drift apart.
4. Push and watch the next `ci.yml` run (on your PR) go green before
   relying on it - `scheduled-build.yml` won't run until its next
   monthly tick or a manual `workflow_dispatch`, so it won't confirm
   this for you on push.

The three actions currently pinned this way: `actions/checkout`,
`ruby/setup-ruby`, `actions/setup-node`.

## 9. Re-confirm green

Once you've made whatever changes were needed, run the complete gate
chain from Step 2 top to bottom one more time, uninterrupted:

```sh
bundle exec ruby script/validate.rb
npm run esbuild
ruby script/check_bundle_size.rb
BRIDGETOWN_ENV=production bundle exec bridgetown build
bundle exec ruby script/check_no_js_content.rb
bundle exec ruby script/check_json_ld.rb
bundle exec htmlproofer output --disable-external --no-enforce-https
```

All seven green locally is the same bar `ci.yml` and
`scheduled-build.yml` enforce. Once it's green:

- Commit the dependency bumps (`Gemfile.lock`, `package-lock.json`,
  `.ruby-version`/`.nvmrc` if changed, workflow YAML if SHAs changed).
- Push and let `ci.yml` confirm it on GitHub's runners too (local and
  CI environments can differ in subtle ways - a red CI run after a
  green local run is itself useful signal).
- Optionally trigger `scheduled-build.yml` manually via its
  `workflow_dispatch` trigger (Actions tab -> "Scheduled rot check" ->
  "Run workflow") to confirm the rot check itself is clean, rather than
  waiting for next month's cron tick.
