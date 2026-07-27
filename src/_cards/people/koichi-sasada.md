---
type: "person"
title: "Koichi Sasada"
hook: "The engineer who gave Ruby a real engine, then taught it to run many things at once."
pronouns: "he/him"
aka:
  - "ko1"
sources:
  - { title: "YARV (Wikipedia)", url: "https://en.wikipedia.org/wiki/YARV" }
  - { title: "Activity list of Koichi Sasada (atdot.net)", url: "https://www.atdot.net/~ko1/activities/" }
  - { title: "Ruby contributors (official docs, ruby-lang.org)", url: "https://docs.ruby-lang.org/en/2.7.0/contributors_rdoc.html" }
---

**Koichi Sasada**, known online as **ko1**, is a longtime Ruby core committer (one of the people trusted to change Ruby's source code) who built the engine that runs your Ruby programs. That engine is **YARV**, short for "Yet Another Ruby VM." Here is what a "bytecode VM" means without the jargon: before Ruby runs your code, YARV first translates it into a compact list of small, simple instructions called *bytecode*, then a *virtual machine* (a program that behaves like a pretend CPU) executes those instructions one by one. Doing the translation once up front, instead of re-reading your source over and over, is a big speedup. The official Ruby docs credit him plainly: "He wrote YARV." YARV was merged into Ruby's repository on January 1, 2007 and shipped as the new heart of [[ruby-1-9]], the big Christmas 2007 release, replacing the older, slower interpreter. If you want the fuller story of Ruby's main implementation and its virtual machine, see [[mri-cruby-yarv]].

He did not stop at speed. Koichi also designed **Ractor**, the actor-based concurrency feature introduced in [[ruby-3-0]] in 2020, which lets a Ruby program do several things at the same time by running work in separate, mostly-isolated units that pass messages instead of sharing memory (the "actor" idea borrowed from languages like Erlang). He first proposed it under the name "guild" before it became Ractor. He also worked for years on Ruby's **garbage collector**, the behind-the-scenes janitor that reclaims memory a program is no longer using, including the generational GC that landed in Ruby 2.1. Along the way he has been employed to work on Ruby by companies including Cookpad and, more recently, STORES, and he is a familiar face keynoting conferences like RubyKaigi and EuRuKo.

*Related:* [[matz]] · [[ruby-1-9]] · [[ruby-3-0]] · [[mri-cruby-yarv]]

## Sources
- YARV (Wikipedia, on YARV as a bytecode interpreter, its author, and the 1.9.0 release on 2007-12-26): https://en.wikipedia.org/wiki/YARV
- Activity list of Koichi Sasada (atdot.net, for Ractor, garbage collection work, and employers): https://www.atdot.net/~ko1/activities/
- Ruby contributors (official docs, ruby-lang.org, "He wrote YARV"): https://docs.ruby-lang.org/en/2.7.0/contributors_rdoc.html
