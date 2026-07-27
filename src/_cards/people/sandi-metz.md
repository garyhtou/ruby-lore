---
type: "person"
title: "Sandi Metz"
hook: "Ruby's clear voice on object design, and the person who taught the community when NOT to abstract."
pronouns: "she/her"
sources:
  - { title: "Sandi Metz (Wikipedia)", url: "https://en.wikipedia.org/wiki/Sandi_Metz" }
  - { title: "The Wrong Abstraction (Sandi Metz, 2016)", url: "https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction" }
identity_urls:
  - "https://en.wikipedia.org/wiki/Sandi_Metz"
  - "https://www.wikidata.org/wiki/Q19588831"
---

**Sandi Metz** is a programmer, teacher, and consultant best known for writing **Practical Object-Oriented Design in Ruby** (2012), a book so widely read it is usually just called **POODR**. It is many Rubyists' first real guide to shaping classes and objects so that code stays easy to change later, which is the whole point she keeps returning to: good design is less about getting it perfect and more about keeping it changeable. She later wrote **99 Bottles of OOP** with [[katrina-owen]], a book that walks through refactoring one small problem again and again to show what "better" actually means in practice.

Her single most-quoted idea is a gentle warning against over-cleverness. In a 2016 essay called **[[the-wrong-abstraction]]**, she argues that when you force scattered-but-similar code into one shared abstraction and it turns out to be the wrong fit, every new requirement makes it worse, until the "clean" version is harder to work with than the repetition it replaced. Her line for it: **"duplication is far cheaper than the wrong abstraction."** Her advice when you are stuck with one is refreshingly unsentimental: "When the abstraction is wrong, the fastest way forward is back," meaning you should feel free to re-inline the code and start over rather than defend a bad guess.

She is also a beloved conference speaker and workshop teacher, and her talks are a common on-ramp for developers trying to get better at design without wading through jargon. If POODR taught a generation how to build objects well, "The Wrong Abstraction" taught them the harder lesson of knowing when to leave code alone.

*Related:* [[the-wrong-abstraction]] · [[katrina-owen]]

## Sources
- Sandi Metz (Wikipedia): https://en.wikipedia.org/wiki/Sandi_Metz
- The Wrong Abstraction (Sandi Metz's blog, January 20, 2016): https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction
