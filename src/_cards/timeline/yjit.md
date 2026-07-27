---
type: "release"
title: "YJIT"
hook: "Shopify's just-in-time compiler for Ruby, merged in 3.1 and declared production-ready in 3.2."
dates:
  - { date: 2021-12-25, label: "YJIT merged into Ruby 3.1 (experimental)" }
  - { date: 2022-12-25, label: "YJIT declared production-ready in Ruby 3.2" }
sources:
  - { title: "Ruby 3.1.0 Released (ruby-lang.org)", url: "https://www.ruby-lang.org/en/news/2021/12/25/ruby-3-1-0-released/" }
  - { title: "Ruby 3.2.0 Released (ruby-lang.org)", url: "https://www.ruby-lang.org/en/news/2022/12/25/ruby-3-2-0-released/" }
---

**YJIT** is a just-in-time compiler for Ruby, built by a team at the e-commerce company Shopify to make Ruby programs run faster. A "JIT compiler" watches your program as it runs, notices the code paths that execute over and over, and translates just those hot spots into native machine code (the low-level instructions a processor runs directly) so they stop going through Ruby's slower general-purpose interpreter. Ruby 3.1 "merges YJIT, a new in-process JIT compiler developed by Shopify" on **December 25, 2021**, where it shipped as experimental and off by default, showing gains like 22% on a Rails benchmark.

One year later, in **Ruby 3.2** on December 25, 2022, YJIT was "no longer experimental," having "been tested on production workloads for over a year and proven to be quite stable." By then its internals were being written in the Rust programming language, so building it required a Rust compiler. YJIT was part of the long push for speed that also drove [[ruby-3-0]]'s "Ruby 3x3" goal.

*Related:* [[ruby-3-0]] · [[ruby-4-0]] · [[the-christmas-release-tradition]]

## Sources
- Ruby 3.1.0 Released (official announcement, YJIT merged, Shopify): https://www.ruby-lang.org/en/news/2021/12/25/ruby-3-1-0-released/
- Ruby 3.2.0 Released (official announcement, YJIT no longer experimental, Rust build requirement): https://www.ruby-lang.org/en/news/2022/12/25/ruby-3-2-0-released/
