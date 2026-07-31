# Ruby Lore

A friendly history of Ruby, chunky bacon and all.

A warm, archival, browsable history of the Ruby programming language: its
people, stories, talks, vocabulary, and a timeline of how it all happened.
Built to welcome brand-new Rubyists and delight thirty-year veterans, and to
be a durable, citable community reference.

## Official domains

- **[chunkybacon.dev](https://chunkybacon.dev)**: the primary, canonical home.
- **[rubylore.dev](https://rubylore.dev)**: a secondary official domain. It
  permanently (301) redirects to `chunkybacon.dev`.

Both are official domains for Ruby Lore; any other domain is unaffiliated.

## Tech

A static site built with [Bridgetown](https://www.bridgetownrb.com/) (Ruby) +
esbuild. Semantic, JavaScript-optional content layer with a progressively
enhanced, animated experience layer on top; self-hosted fonts; JSON-LD,
sitemap, and an AI-crawler-friendly `robots.txt`.

## Contributing

Corrections and additions are welcome. See
[`CONTRIBUTING.md`](./CONTRIBUTING.md). To run it locally:

```sh
bundle install && npm ci
bin/bridgetown start   # dev server with live reload
```

Deployment and launch steps are in [`docs/deploy.md`](./docs/deploy.md).

## License

Ruby Lore is dual-licensed to keep both the code and the content as open as
possible:

- **Source code**: the [MIT License](./LICENSE).
- **Written content** (the card entries and pages) and the Ruby Lore fox mark:
  [Creative Commons Attribution 4.0 (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).
  The full legal text is in [`LICENSE-CONTENT`](./LICENSE-CONTENT); see
  [`docs/content-license.md`](./docs/content-license.md) for how to attribute
  reuse and a note on the mark's trademark reservation.

Bundled fonts keep their own SIL Open Font License (OFL).

## How this was built

AI coding tools helped build this site, and helped with research. All copy was
curated by humans: read, written, edited, fact-checked against the sources
cited on each page, and signed off before it shipped. See
[Credits](https://chunkybacon.dev/credits/) for the people and archives this
site stands on.
