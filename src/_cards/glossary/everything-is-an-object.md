---
type: "vocabulary"
title: "Everything is an Object"
hook: "In Ruby even a plain number or nil is a real object you can call methods on."
sources:
  - { title: "About Ruby (ruby-lang.org)", url: "https://www.ruby-lang.org/en/about/" }
---

**Everything is an object** in Ruby: every value you touch is a real object that carries its own methods, including plain numbers, `nil`, `true` and `false`, and even classes themselves. There are no second-class "primitives" sitting outside the object system the way there are in some other languages. That is why the number 5 can answer messages directly: you can write `5.times { puts "hi" }` to repeat something five times, ask `(-5).abs` to get `5` back, or call `nil.to_s` and get an empty string. It is a big part of what people mean when they say Ruby is built to [[optimize-for-programmer-happiness]]: the rules stay the same everywhere, so there is less to memorize.

*Related:* [[optimize-for-programmer-happiness]] · [[monkey-patching]] · [[duck-typing]]

## Sources
- About Ruby (ruby-lang.org), "In Ruby, everything is an object" and the `5.times` example: https://www.ruby-lang.org/en/about/
