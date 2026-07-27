---
type: "release"
title: "Ruby 1.9"
hook: "The Christmas-2007 modernization that gave Ruby a real virtual machine and a new way to handle text."
dates:
  - { date: 2007-12-25, label: "Ruby 1.9.0 released" }
sources:
  - { title: "Ruby 1.9.0 Released (ruby-lang.org news)", url: "https://www.ruby-lang.org/en/news/2007/12/25/ruby-1-9-0-released/" }
  - { title: "YARV, Wikipedia", url: "https://en.wikipedia.org/wiki/YARV" }
  - { title: "Gray Soft: Understanding M17n (Multilingualization)", url: "http://graysoftinc.com/character-encodings/understanding-m17n-multilingualization" }
---

Ruby **1.9.0** shipped on **December 25, 2007**, announced by [[matz]] as a development release: an early, partly-breaking preview of the next major Ruby rather than a polished stable one. Landing on Christmas Day, it is one more entry in [[the-christmas-release-tradition]].

Two big changes made it a genuine modernization. First, Ruby 1.9 ran on **YARV** ("Yet another Ruby VM"), a bytecode virtual machine written by [[koichi-sasada]]. A bytecode VM compiles your code into compact instructions and runs those, instead of re-walking the program's tree structure line by line; YARV became the official Ruby interpreter starting with 1.9 and ran benchmarks several times faster than the older approach. Second, it overhauled how strings handle character encodings, adding the "m17n" (multilingualization) engine so a String carried both its raw bytes and the encoding needed to read them, supporting many more encodings than 1.8 did. The performance ambitions here echoed forward years later into the "Ruby 3x3" goal of [[ruby-3-0]].

*Related:* [[koichi-sasada]] · [[the-christmas-release-tradition]] · [[ruby-3-0]]

## Sources
- Ruby 1.9.0 Released (official announcement, ruby-lang.org, posted 25 Dec 2007; "Matz announced the release of Ruby 1.9.0, a development release"): https://www.ruby-lang.org/en/news/2007/12/25/ruby-1-9-0-released/
- YARV, Wikipedia (Yet another Ruby VM, developed by Koichi Sasada; became the official Ruby interpreter for Ruby 1.9): https://en.wikipedia.org/wiki/YARV
- Gray Soft, Understanding M17n / Multilingualization (Ruby 1.9's new encoding engine; String as encoded data with attached encoding): http://graysoftinc.com/character-encodings/understanding-m17n-multilingualization
