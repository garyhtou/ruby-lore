# Contributing to Ruby Lore

Ruby Lore (chunkybacon.dev) is a friendly, factual, kind history of the
Ruby programming language: its people, stories, talks, vocabulary, and
timeline. It's a small site, but it makes real claims about real people,
so it only works if it stays accurate. That's where you come in.

You don't need to be a Ruby veteran, a programmer, or a Git expert to
contribute. If you spot something wrong, or know a story worth telling,
we want to hear it.

## The fastest way to help: report a correction

If you noticed a mistake, or think something's missing, [open a
correction issue][correction-issue]. It's a short form: which page, what's
wrong, what it should say instead, and a source if you have one. A
maintainer will take it from there.

There's also a [general suggestion form][suggestion-issue] for new-card
ideas, questions, or anything that isn't a correction.

## Proposing a change yourself

Prefer to make the edit directly? Every card page has a small **"Edit
this page on GitHub"** link at the bottom that opens GitHub's editor
right on that card's source file. Make your change, describe it, and
open a pull request, GitHub will guide you through forking the repo if
you don't already have write access.

The [pull request template][pr-template] includes a short review
checklist. It's there to help you self-check before a maintainer looks,
not to gatekeep.

### The content model, briefly

Each card is one Markdown file at `src/_cards/<segment>/<slug>.md`
(`people/`, `stories/`, `talks/`, `glossary/`, or `timeline/`, matching
the card's `type`). A card needs, at minimum:

- YAML front matter with a `type` and a `title`.
- A `## Sources` section at the end, with at least one real citation
  (a link, a talk, an interview, anything checkable).

Cards can link to each other with `[[slug]]`, which becomes a real link
at build time (the slug is just the filename, e.g. `[[matz]]`).

Before opening a pull request, it helps to run the content validator
locally:

```
bundle exec ruby script/validate.rb
```

It checks that every card has the required fields, that `[[slug]]` links
resolve, and that sources are present, the same checks CI runs.

If you touch any Ruby, also run the linter (Standard, which auto-fixes
most issues):

```
bundle exec standardrb --fix
```

CI runs `bundle exec standardrb` and fails on any remaining offense.

## The editorial spirit

Ruby Lore's whole reason for existing is that it's accurate, sourced,
and kind. A few things that fall out of that, worth keeping in mind for
both corrections and new cards:

- **Back claims with sources.** A date, a quote, an attribution, all of
  it should be checkable. When in doubt, cite it.
- **Be kind, especially about people.** This is a celebration of Ruby's
  history, not a place to settle scores. Describe divisive figures and
  their work factually and fairly, without piling on praise or taking
  sides in disagreements the community itself hasn't settled.
- **Let live controversy stay unresolved.** If something is still an
  active, unsettled dispute, stick to neutral, sourced facts rather than
  narrating where things currently stand. That can always be filled in
  later, once there's more distance.
- **Respect chosen anonymity.** Some figures in Ruby's history, most
  notably _why the lucky stiff, are known by a pseudonym they chose to
  keep, deliberately, apart from their legal identity. Ruby Lore never
  publishes, links to, or hints at that identity, and we ask
  contributors to do the same: prefer name-respectful sources, and never
  link a page (even an otherwise good one) that reveals a
  chosen-anonymous person's legal name.

If you're ever unsure whether something fits, open the correction or
suggestion form and ask, that's what it's for.

## Licensing of your contributions

Ruby Lore is dual-licensed: its source code under the MIT License, and its
written content and the Ruby Lore fox mark under Creative Commons Attribution
4.0 (CC BY 4.0). See [`LICENSE`](./LICENSE) and
[`LICENSE-CONTENT`](./LICENSE-CONTENT).

By opening a pull request or a correction, you agree that your contribution is
provided under those same terms (inbound = outbound): code contributions under
the MIT License, and content contributions under CC BY 4.0. You confirm you
have the right to contribute it, and that any third-party material you include
(a quote, for example) is properly attributed and used in a way its own license
or fair use permits. You keep the copyright to your contribution; you're just
licensing it on the same terms as the rest of the project.

## Questions

Open a [general suggestion issue][suggestion-issue], or start a
discussion on a pull request. Thanks for helping keep Ruby Lore honest.

[correction-issue]: https://github.com/garyhtou/ruby-lore/issues/new?template=correction.yml
[suggestion-issue]: https://github.com/garyhtou/ruby-lore/issues/new?template=general-suggestion.yml
[pr-template]: https://github.com/garyhtou/ruby-lore/blob/main/.github/PULL_REQUEST_TEMPLATE.md
