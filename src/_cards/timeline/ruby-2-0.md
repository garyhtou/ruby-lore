---
type: "release"
title: "Ruby 2.0"
hook: "Ruby's 20th-birthday release, shipped on the exact day the name was chosen twenty years earlier."
dates:
  - { date: 2013-02-24, label: "Ruby 2.0.0 released" }
sources:
  - { title: "Ruby 2.0.0-p0 is released (ruby-lang.org)", url: "https://www.ruby-lang.org/en/news/2013/02/24/ruby-2-0-0-p0-is-released/" }
  - { title: "Ruby 2.0.0 adds syntax sparkle, boosts performance (The Register, 2013)", url: "https://www.theregister.com/2013/02/26/ruby_2_released/" }
---

Ruby 2.0.0 shipped on **February 24, 2013**, exactly twenty years to the day after [[matz]] picked the name "Ruby" in a 1993 chat ([[named-before-it-existed]]), so it doubled as the language's twentieth-birthday release. Its headline additions were **keyword arguments** (naming a method's arguments when you call it, like `render(status: 200)`, instead of relying on their order) and **refinements** (a safer, scoped way to add or change methods on an existing class so the change only applies where you switch it on, rather than everywhere at once). Refinements shipped as experimental.

A deliberate goal this time was staying easy to upgrade to. Coming off the disruptive [[ruby-1-9]] transition, the team designed 2.0 to stay close to 1.9, writing that "it will be easier to migrate from 1.9 to 2.0 than it was from 1.8 to 1.9," and noting that applications like Rails were already reported working on the release candidate.

*Related:* [[named-before-it-existed]] · [[ruby-1-9]] · [[matz]]

## Sources
- Ruby 2.0.0-p0 is released (official announcement, ruby-lang.org): https://www.ruby-lang.org/en/news/2013/02/24/ruby-2-0-0-p0-is-released/
- Ruby 2.0.0 adds syntax sparkle, boosts performance (The Register, 2013): https://www.theregister.com/2013/02/26/ruby_2_released/
