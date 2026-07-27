---
type: "vocabulary"
title: "MRI / CRuby / YARV"
hook: "Three names for the standard Ruby you download: whose it is, what it is written in, and the engine inside."
sources:
  - { title: "About Ruby (ruby-lang.org)", url: "https://www.ruby-lang.org/en/about/" }
  - { title: "YARV (Wikipedia)", url: "https://en.wikipedia.org/wiki/YARV" }
  - { title: "Global interpreter lock (Wikipedia)", url: "https://en.wikipedia.org/wiki/Global_interpreter_lock" }
---

The Ruby you download from ruby-lang.org is one program that goes by several nicknames, and each one describes it from a different angle. Ruby's own site calls it **MRI**, for **"Matz's Ruby Interpreter,"** after the language's creator [[matz]], and also **CRuby**, "since it is written in C". The third name, **YARV** ("Yet another Ruby VM"), is the bytecode virtual machine that lives inside it: instead of re-reading your source over and over, it first compiles your code into compact instructions that the machine then runs. YARV was written by [[koichi-sasada]] and became the official engine in [[ruby-1-9]]. One more piece of vocabulary you will bump into: this interpreter has a **Global VM Lock** (GVL, and you will also see it called a GIL, for global interpreter lock), a lock that lets only one thread run Ruby code at a time. So MRI, CRuby, and YARV are not three different Rubies: they are three names pointing at the same one.

*Related:* [[matz]] · [[ruby-1-9]] · [[koichi-sasada]]

## Sources
- About Ruby (MRI = "Matz's Ruby Interpreter"; CRuby = written in C): https://www.ruby-lang.org/en/about/
- YARV ("Yet another Ruby VM"; Koichi Sasada; official in Ruby 1.9): https://en.wikipedia.org/wiki/YARV
- Global interpreter lock (Ruby MRI's is called the Global VM Lock; one thread at a time): https://en.wikipedia.org/wiki/Global_interpreter_lock
