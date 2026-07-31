# Deploying Ruby Lore

Ruby Lore is a static site served at its canonical domain
`https://chunkybacon.dev`. It is deployed across four services:

| Service | Role |
| --- | --- |
| **Porkbun** | Registrar for `chunkybacon.dev` (primary) and `rubylore.dev` (secondary). |
| **Cloudflare** | DNS for both domains, and the `rubylore.dev` → `chunkybacon.dev` redirect. |
| **GitHub Pages** | Hosts the built site. |
| **Cloudflare Web Analytics** | Privacy-friendly, cookieless traffic stats. |

## How it fits together

- **DNS: Cloudflare.** `chunkybacon.dev` points at GitHub Pages, unproxied
  (DNS-only), so GitHub serves the site and its TLS certificate directly and
  AI crawlers reach it unblocked. `rubylore.dev` is Cloudflare-proxied and
  issues a single-hop, path-preserving **301** to `chunkybacon.dev`.
- **Hosting: GitHub Pages.** The site is built and published by a GitHub
  Actions workflow (`.github/workflows/pages.yml`) on each successful CI run
  on `main`, with `chunkybacon.dev` configured as the custom domain.
- **Analytics: Cloudflare Web Analytics.** Loaded via a beacon in
  `src/_partials/_head.erb`, emitted in production builds only.
