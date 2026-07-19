# Ruby Lore

A friendly history of Ruby, chunky bacon and all.

A warm, archival, browsable history of the Ruby programming language: its
people, stories, talks, vocabulary, and a timeline of how it all happened.
Built to welcome brand-new Rubyists and delight thirty-year veterans, and to
be a durable, citable community reference.

## Official domains

- **[chunkybacon.dev](https://chunkybacon.dev)**, the primary, canonical home.
- **[rubylore.dev](https://rubylore.dev)**, a secondary official domain. It
  permanently (301) redirects to `chunkybacon.dev`.

Both are official domains for Ruby Lore; any other domain is unaffiliated.

## Tech

A static site built with [Bridgetown](https://www.bridgetownrb.com/) (Ruby) +
esbuild. Semantic, JavaScript-optional content layer with a progressively
enhanced, animated experience layer on top; self-hosted fonts; JSON-LD,
sitemap, and an AI-crawler-friendly `robots.txt`.

## Contributing

Corrections and additions are welcome, see
[`CONTRIBUTING.md`](./CONTRIBUTING.md). To run it locally:

```sh
bundle install && npm ci
bin/bridgetown start   # dev server with live reload
```

Deployment and launch steps are in [`docs/deploy.md`](./docs/deploy.md).
