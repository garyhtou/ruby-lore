---
type: "vocabulary"
title: "\"Ruby is dead\""
hook: "The recurring claim that Ruby is dying, and the specific, sourced reason it is not: it still ships every year and still runs some of the busiest, most valuable companies on the web."
sources:
  - { title: "isrubydead.com", url: "http://isrubydead.com/" }
  - { title: "Ruby releases (ruby-lang.org)", url: "https://www.ruby-lang.org/en/downloads/releases/" }
  - { title: "Ruby 4.0.0 Released (ruby-lang.org)", url: "https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/" }
  - { title: "Building GitHub with Ruby and Rails (The GitHub Blog)", url: "https://github.blog/engineering/architecture-optimization/building-github-with-ruby-and-rails/" }
  - { title: "Ruby YJIT Is Production-Ready (Shopify Engineering)", url: "https://shopify.engineering/ruby-yjit-is-production-ready" }
  - { title: "Ruby 3.3's YJIT Runs Shopify's Production Code 15% Faster (Rails at Scale)", url: "https://railsatscale.com/2023-09-18-ruby-3-3-s-yjit-runs-shopify-s-production-code-15-faster/" }
  - { title: "Sorbet: Stripe's type checker for Ruby (Stripe Engineering)", url: "https://stripe.dev/blog/sorbet-stripes-type-checker-for-ruby" }
  - { title: "37signals (Rails Foundation member page)", url: "https://rubyonrails.org/foundation/37signals" }
  - { title: "The history of infrastructure at Zendesk (Zendesk Engineering)", url: "https://zendesk.engineering/the-history-of-infrastructure-at-zendesk-constant-tradeoffs-bdfa916ff4c3" }
  - { title: "Scaling at Instacart: distributing data across Postgres databases with Rails (Instacart Engineering)", url: "https://tech.instacart.com/scaling-at-instacart-distributing-data-across-multiple-postgres-databases-with-rails-13b1e4eba202" }
  - { title: "The long game: why Rails survived the hype cycle (Irina Nazarova, Evil Martians)", url: "https://evilmartians.com/chronicles/the-long-game-why-rails-survived-the-hype-cycle-and-what-it-means-for-your-startup" }
  - { title: "Startups on Rails in 2024: my RailsConf keynote (Irina Nazarova, Evil Martians)", url: "https://evilmartians.com/chronicles/startups-on-rails-in-2024-my-keynote-at-railsconf" }
  - { title: "Which programming language is best for Claude Code? (Yusuke Endoh / mame, dev.to)", url: "https://dev.to/mame/which-programming-language-is-best-for-claude-code-508a" }
  - { title: "Mastodon developer overview (docs.joinmastodon.org)", url: "https://docs.joinmastodon.org/dev/overview/" }
  - { title: "Tuple full-stack role (Rails backend)", url: "https://tuple.app/jobs/full-stack" }
  - { title: "Campfire (once-campfire, 37signals, GitHub)", url: "https://github.com/basecamp/once-campfire" }
  - { title: "2024 Ruby on Rails Community Survey", url: "https://railsdeveloper.com/survey/2024/" }
  - { title: "Official Ruby SDK for the OpenAI API (GitHub)", url: "https://github.com/openai/openai-ruby" }
  - { title: "Anthropic Ruby SDK (Claude SDK for Ruby, GitHub)", url: "https://github.com/anthropics/anthropic-sdk-ruby" }
  - { title: "RubyLLM (crmne/ruby_llm, GitHub)", url: "https://github.com/crmne/ruby_llm" }
  - { title: "Langchain.rb (patterns-ai-core/langchainrb, GitHub)", url: "https://github.com/patterns-ai-core/langchainrb" }
  - { title: "Introducing Roast (Shopify Engineering)", url: "https://shopify.engineering/introducing-roast" }
---

**No.** Ruby is not dead, and the reasons are specific rather than sentimental. "Ruby is dead" is a headline that has been written, in one form or another, for well over a decade, so often that it has become a community in-joke with its own single-serving website: [isrubydead.com](http://isrubydead.com/), which answers the perennial question with one word, "No." The joke is the fun part. What follows is why the facts keep agreeing with it.

**The language still ships, every year, on schedule.** Ruby has delivered a new version on Christmas Day for years running, an unbroken tradition ([[the-christmas-release-tradition]]). The most recent, [[ruby-4-0]], arrived on December 25, 2025, three decades after Ruby's first public release. A new major version, shipped on a fixed annual calendar by an active core team, is not what an abandoned language looks like.

**Some of the biggest names on the web run on Ruby right now.** These are not nostalgia projects; they are current, load-bearing systems, and their own engineering teams say so:

- **Shopify** describes "Ruby as well as Ruby on Rails" as "central to the infrastructure behind all Shopify stores and much of the modern web," and it staffs a team dedicated to making Ruby itself faster.
- **GitHub** writes plainly that "since the beginning, GitHub.com has been a Ruby on Rails monolith" (a monolith being one single codebase deployed as one application, rather than many small separate services), and it upgrades Rails so aggressively that an automated pull request, a proposed code change, bumps its Rails version to the latest commit on the Rails main branch every Monday.
- **Stripe** says most of its code "still is written in Ruby, which is famous for helping engineers iterate quickly," a codebase it measures at "over 15 million lines of code spread across 150,000 files."
- **37signals**, the maker of Basecamp, is "the birthplace of Rails, which was started in 2003 to build Basecamp," and it "has since used it to create all their web products."
- **Zendesk** was built on Ruby on Rails from its early days, and **Instacart** writes publicly about scaling on Rails.

**And it is still being chosen for new work, not just maintained.** The pull is not only old codebases running on inertia. **Mastodon**, the decentralized social network that surged in 2022, is a Rails app, and **Tuple**, a remote pair-programming tool around since 2018, runs its backend on Rails. 37signals keeps building brand-new products on it too, from HEY to its more recent self-hosted Campfire, a chat app you run on your own server. Even among developers already using Rails, in the 2024 Rails Community Survey most reported shipping a *new* Rails app in the past two years, a sign the community is not only maintaining old code. And Evil Martians, a consultancy that works with Rails startups, argues the trend is current: its CEO **Irina Nazarova** says Rails once powered around 90% of the early batches at Y Combinator (an influential startup accelerator), and for her 2024 RailsConf keynote she interviewed 25 founders and technical leaders whose companies had recently chosen it. Among the fast-growing companies it counts in that Rails ecosystem are **Bolt.new** ($40 million in annual recurring revenue, its yearly subscription run-rate, within five months), **Whop** (over $1.4 billion in transactions), and **Uscreen** (a $150 million deal).

**Ruby keeps getting faster.** A large share of Ruby's recent engineering has gone straight at performance, a direct answer to its old reputation for being slow. The effort is not new: Matz set a public "Ruby 3x3" goal to make Ruby 3 markedly faster than Ruby 2, which [[ruby-3-0]] delivered on in 2020. [[yjit]], a just-in-time compiler built by Shopify (a JIT compiler speeds a program up by translating its busiest code into fast machine instructions while the program runs), was declared "production-ready" in Ruby 3.2, and on Ruby 3.3 it ran Shopify's production code about 15% faster just by being switched on. Ruby 4.0 then shipped **ZJIT**, described in the official release notes as "the next generation of YJIT," from the same compiler team ([[ruby-4-0]]). The performance story is one of steady, measurable progress that is still being written.

**What Ruby is known for: productivity.** Its reputation rests on letting developers move quickly. Stripe calls Ruby "famous for helping engineers iterate quickly," and Rails was built at 37signals so a small team could ship a real product fast. That same pairing, fast iteration on top of a deep and mature ecosystem, is what a solo developer and a large engineering organization like GitHub or Shopify are each drawing on.

**Ruby is a comfortable home for building with AI.** For wiring language models into real products, it is well covered. Both **OpenAI** and **Anthropic** ship official Ruby SDKs, ready-made toolkits for calling their models, and libraries like **RubyLLM** and **Langchain.rb** make it straightforward to call models and build agents, programs that let a model take actions on its own, from a Rails app. Shopify open-sourced **Roast**, a Ruby framework for structured AI workflows that it describes as "itself implemented in Ruby." There is a fun data point, too: in one 2026 experiment by the Ruby committer [[yusuke-endoh]], Claude wrote the same small program across thirteen languages, and Ruby, Python, and JavaScript came out the fastest and cheapest for the model to produce, with Ruby narrowly first. The same quick-iteration story that made Rails good for shipping web apps applies to shipping AI features.

**And underneath the companies, there are people.** A language stays alive because a community keeps showing up for it, and Ruby's is one of the warmest in software. Its unofficial motto is **[[minaswan]]**, "Matz is nice and so we are nice," named for the language's creator [[matz]], and that spirit shows up in local meetups, mentorship for newcomers, and famously welcoming conferences. If you are weighing whether to learn Ruby, that is the part the benchmarks miss: you would not be joining a museum, but a living community that still ships, still hires, and still goes out of its way to help beginners get started.

The honest summary for a newcomer: "is X dead?" gets asked about nearly every mature technology, and for Ruby the specific, sourced answer has stayed "No" for years, backed by yearly releases, active core-team work on speed, and a roster of large companies that quietly depend on it.

*Related:* [[ruby-4-0]] · [[yjit]] · [[ruby-3-0]] · [[the-christmas-release-tradition]] · [[matz]]

## Sources
- isrubydead.com (answers the question "Is Ruby dead?" with "No"): http://isrubydead.com/
- Ruby releases (ongoing release history, including the yearly December 25 releases): https://www.ruby-lang.org/en/downloads/releases/
- Ruby 4.0.0 Released (ruby-lang.org; December 25, 2025, introduces ZJIT "the next generation of YJIT"): https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/
- Building GitHub with Ruby and Rails (The GitHub Blog; "GitHub.com has been a Ruby on Rails monolith," weekly Rails-main upgrades): https://github.blog/engineering/architecture-optimization/building-github-with-ruby-and-rails/
- Ruby YJIT Is Production-Ready (Shopify Engineering; Ruby/Rails "central to the infrastructure behind all Shopify stores," YJIT production-ready in 3.2): https://shopify.engineering/ruby-yjit-is-production-ready
- Ruby 3.3's YJIT Runs Shopify's Production Code 15% Faster (Rails at Scale): https://railsatscale.com/2023-09-18-ruby-3-3-s-yjit-runs-shopify-s-production-code-15-faster/
- Sorbet: Stripe's type checker for Ruby (Stripe Engineering; most code "still is written in Ruby," "over 15 million lines"): https://stripe.dev/blog/sorbet-stripes-type-checker-for-ruby
- 37signals (Rails Foundation member page; "birthplace of Rails," builds "all their web products" on it): https://rubyonrails.org/foundation/37signals
- The history of infrastructure at Zendesk (Zendesk Engineering; chose Ruby on Rails in 2005): https://zendesk.engineering/the-history-of-infrastructure-at-zendesk-constant-tradeoffs-bdfa916ff4c3
- Scaling at Instacart with Rails (Instacart Engineering): https://tech.instacart.com/scaling-at-instacart-distributing-data-across-multiple-postgres-databases-with-rails-13b1e4eba202
- The long game: why Rails survived the hype cycle (Irina Nazarova, Evil Martians; ~90% of early Y Combinator batches launched on Rails): https://evilmartians.com/chronicles/the-long-game-why-rails-survived-the-hype-cycle-and-what-it-means-for-your-startup
- Startups on Rails in 2024 (Irina Nazarova, Evil Martians; RailsConf 2024 keynote, 25 founders/CTOs who recently chose Rails): https://evilmartians.com/chronicles/startups-on-rails-in-2024-my-keynote-at-railsconf
- Which programming language is best for Claude Code? (Yusuke Endoh / mame, dev.to, 2026; Ruby fastest and cheapest for the model to write across 13 languages): https://dev.to/mame/which-programming-language-is-best-for-claude-code-508a
- Mastodon developer overview (docs.joinmastodon.org; "Mastodon is a Ruby on Rails application with a React.js front-end"): https://docs.joinmastodon.org/dev/overview/
- Tuple full-stack role (backend is a "monolithic Ruby on Rails application"): https://tuple.app/jobs/full-stack
- Campfire (once-campfire, 37signals; self-hosted group chat, a Rails app): https://github.com/basecamp/once-campfire
- 2024 Ruby on Rails Community Survey (most respondents shipped a new Rails app in the past two years, working mostly on new apps): https://railsdeveloper.com/survey/2024/
- Official Ruby SDK for the OpenAI API (GitHub): https://github.com/openai/openai-ruby
- Anthropic Ruby SDK (Claude SDK for Ruby, GitHub): https://github.com/anthropics/anthropic-sdk-ruby
- RubyLLM (unified Ruby interface to LLM providers, with Rails integration): https://github.com/crmne/ruby_llm
- Langchain.rb (build LLM apps in Ruby): https://github.com/patterns-ai-core/langchainrb
- Introducing Roast (Shopify Engineering; "Roast is itself implemented in Ruby"): https://shopify.engineering/introducing-roast
