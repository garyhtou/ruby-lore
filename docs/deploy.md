# Deploying Ruby Lore

Ruby Lore is a static site (Bridgetown + esbuild) that deploys to **GitHub
Pages** via `.github/workflows/pages.yml`. The workflow builds the production
site and publishes it after CI passes on `main`.

The site is built for **root-path serving** at its canonical domain
`https://chunkybacon.dev` (all internal links and the `sitemap`/`canonical`/
`JSON-LD` URLs assume the apex). So it needs the **custom domain** to be
configured; the bare `*.github.io/<repo>/` sub-path URL would break asset and
link paths.

## One-time setup

### 1. Register the domains

- **chunkybacon.dev** (canonical) and **rubylore.dev** (redirect).
- Turn on **auto-renew**. `.dev` is on the HSTS preload list, so HTTPS is
  always enforced.
- Any at-cost registrar is fine (e.g. Porkbun or Cloudflare Registrar).

### 2. Enable GitHub Pages (Actions source)

In the repo: **Settings -> Pages -> Build and deployment -> Source:
"GitHub Actions"**. (Not "Deploy from a branch" - this repo builds with a
custom Ruby/Node toolchain, which only the Actions workflow can do.)

### 3. Point DNS at GitHub Pages

For the **apex** `chunkybacon.dev`, add A/AAAA records to GitHub's Pages IPs
(or an ALIAS/ANAME/CNAME-flattening record to `<user>.github.io` if your DNS
host supports it):

```
A     chunkybacon.dev  185.199.108.153
A     chunkybacon.dev  185.199.109.153
A     chunkybacon.dev  185.199.110.153
A     chunkybacon.dev  185.199.111.153
```

(Check GitHub's docs for the current Pages IP addresses before relying on the
list above.) The `CNAME` file at the repo root of the built site
(`src/CNAME`) tells Pages the custom domain automatically on every deploy.

GitHub then provisions a Let's Encrypt certificate for the domain (can take a
few minutes to an hour). Confirm HTTPS works, then optionally enable
"Enforce HTTPS" in Settings -> Pages.

### 4. Redirect rubylore.dev -> chunkybacon.dev (single-hop 301)

Set up a **URL forward** at the registrar (Porkbun's URL Forwarding, or a
Cloudflare Redirect Rule) from `rubylore.dev` to `https://chunkybacon.dev`,
path-preserving, as a **301**. Verify one hop:

```
curl -I https://rubylore.dev/timeline/   # expect a single 301 -> chunkybacon.dev/timeline/
```

## The one thing that can silently kill the mission: AI crawlers

Ruby Lore's whole point is to be crawled and cited by AI and search. GitHub
Pages **serves every user-agent by default** (no AI-bot firewall), so this
works out of the box - as long as you do NOT put a proxy in front that blocks
AI bots.

- If you use **Cloudflare for DNS**, keep `chunkybacon.dev` **"DNS only"
  (grey cloud)**, not proxied (orange cloud). Proxying re-introduces
  Cloudflare's default AI-bot blocking, which `robots.txt` cannot override.
- After going live, verify every major AI crawler gets `200` (not `403`/a
  challenge):

```
for ua in GPTBot ClaudeBot CCBot PerplexityBot OAI-SearchBot Google-Extended; do
  curl -s -o /dev/null -w "$ua %{http_code}\n" -A "$ua" https://chunkybacon.dev/
done
```

Re-run this after any DNS/host change.

## Launch checklist

- [ ] Domains registered + auto-renew on; DNS pointed; HTTPS green.
- [ ] `rubylore.dev` -> `chunkybacon.dev` is a single-hop 301.
- [ ] AI-crawler probe above returns `200` for every bot.
- [ ] Google Search Console: verify the property, submit `sitemap.xml`.
- [ ] Add privacy-respecting analytics (e.g. GoatCounter) if wanted.
- [ ] Paste a card URL into a social-preview checker; confirm the OG image
      (`/images/og-share.png`) renders.
- [ ] Decide the license (the shipped `LICENSE` is a TBD placeholder; the
      choice affects reuse and AI-training inclusion).
- [ ] (Recommended, not blocking) complete the veteran copy-edit pass before
      a wide announcement.
- [ ] Announce (Show HN / build-in-public); the AI-citability angle is the
      hook.

## Deploying

Every push to `main` runs CI; when CI passes, the Pages workflow publishes
automatically. You can also deploy on demand: **Actions -> Deploy to GitHub
Pages -> Run workflow**.

To build the production site locally (what gets deployed):

```
npm ci && npm run esbuild
BRIDGETOWN_ENV=production bundle exec bridgetown build   # -> output/
```

A bare `bundle exec bridgetown start` runs the dev server (with live-reload)
for local preview. See `docs/runbook-unrot.md` if a build ever breaks.
