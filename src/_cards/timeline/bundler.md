---
type: "release"
title: "Bundler"
hook: "The tool that ended \"dependency hell\" by giving every machine the exact same set of gems."
dates:
  - { date: 2010-08-29, label: "Bundler 1.0.0 released" }
sources:
  - { title: "Bundler 1.0.0 (RubyGems.org release page)", url: "https://rubygems.org/gems/bundler/versions/1.0.0" }
  - { title: "Bundler (official site)", url: "https://bundler.io/" }
  - { title: "A History of Bundles: 2010 to 2017 (André Arko)", url: "https://andre.arko.net/2017/11/16/a-history-of-bundles/" }
  - { title: "Bundler belongs to the Ruby community (André Arko, 2025)", url: "https://andre.arko.net/2025/09/25/bundler-belongs-to-the-ruby-community/" }
  - { title: "Composer: Introduction (\"strongly inspired by node's npm and ruby's bundler\")", url: "https://getcomposer.org/doc/00-intro.md" }
  - { title: "Cargo: predictable dependency management (The Rust Programming Language blog, 2014)", url: "https://blog.rust-lang.org/2014/11/20/Cargo/" }
  - { title: "CPAN (Wikipedia; online since 1995)", url: "https://en.wikipedia.org/wiki/CPAN" }
  - { title: "Introducing Yarn (2016)", url: "https://classic.yarnpkg.com/blog/2016/10/11/introducing-yarn/" }
---

**Bundler** is Ruby's dependency manager: it reads a project's list of required libraries (called gems) and installs the exact versions that work together, so the same code behaves the same way on every developer's laptop and every server. It solved what Rubyists called "dependency hell," where two libraries each wanted a different version of a third one and nothing would install cleanly. You write your gems and version limits in a file named the **Gemfile**, run `bundle install`, and Bundler records the precise versions it chose into a **Gemfile.lock**. Commit that lockfile and every machine gets an identical set of gems.

Bundler 1.0.0 arrived on **August 29, 2010**. The original idea was [[yehuda-katz]]'s, and the first six months of prototypes were the work of Yehuda and Carl Lerche together, a duo prolific enough that people called them "Carlhuda"; André Arko joined in February 2010 and co-authored the 1.0 release with the two of them. It was first built to tame the tangled dependencies of the Merb web framework, then retargeted at Rails after the two projects merged ([[merb-rails-merger]]).

**A quiet influence beyond Ruby.** Bundler did not invent package management. Perl's CPAN had been doing it since 1995, and Ruby's own RubyGems arrived in 2004, six years before Bundler ([[rubygems-at-rubyconf]]). What Bundler is remembered for is being an early, influential example of the **deterministic lockfile**: that `Gemfile.lock`, pinning every resolved version so an install comes out identical on every machine. The idea traveled. PHP's Composer says in its own documentation that it is "strongly inspired by node's npm and ruby's bundler", and Bundler's own co-creators, [[yehuda-katz]] and Carl Lerche, went on to design Rust's package manager, Cargo, which the Rust team introduced as following "the tradition of successes like Bundler and NPM". Comparable lockfiles later became standard in the JavaScript world too, with Yarn in 2016 and npm soon after.

*Related:* [[yehuda-katz]] · [[merb-rails-merger]] · [[rubygems-at-rubyconf]]

## Sources
- Bundler 1.0.0 (RubyGems.org release page, dated August 29, 2010): https://rubygems.org/gems/bundler/versions/1.0.0
- Bundler (official site, Gemfile / Gemfile.lock / dependency hell): https://bundler.io/
- A History of Bundles: 2010 to 2017 (André Arko, on the team and origins): https://andre.arko.net/2017/11/16/a-history-of-bundles/
- Composer: Introduction (states Composer is "strongly inspired by node's npm and ruby's bundler"): https://getcomposer.org/doc/00-intro.md
- Cargo: predictable dependency management (The Rust Programming Language blog, 2014; Cargo, by Bundler co-creators Katz and Lerche, "follows the tradition of successes like Bundler and NPM"): https://blog.rust-lang.org/2014/11/20/Cargo/
- CPAN (Wikipedia; Perl's package archive, online since 1995, predating RubyGems and Bundler): https://en.wikipedia.org/wiki/CPAN
- Introducing Yarn (2016; a deterministic lockfile arriving in the JavaScript world well after Bundler's): https://classic.yarnpkg.com/blog/2016/10/11/introducing-yarn/
