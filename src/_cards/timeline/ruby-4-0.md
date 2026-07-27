---
type: "release"
title: "Ruby 4.0"
hook: "Ruby 4.0, delivered on Christmas Day 2025, introducing ZJIT and the experimental Ruby Box."
dates:
  - { date: 2025-12-25, label: "Ruby 4.0.0 released" }
sources:
  - { title: "Ruby 4.0.0 Released (ruby-lang.org)", url: "https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/" }
---

Ruby 4.0.0 shipped on **December 25, 2025**, keeping [[the-christmas-release-tradition]] alive and landing three decades after Ruby's first public release back in December 1995 ([[ruby-0-95]]). Its two headline additions are **ZJIT** and **Ruby Box**. ZJIT is "a new just-in-time (JIT) compiler, which is developed as the next generation of YJIT": a JIT compiler speeds a program up by translating its hot code into native machine instructions while it runs, and this one succeeds the earlier [[yjit]]. The announcement is candid that "ZJIT is faster than the interpreter, but not yet as fast as YJIT."

Ruby Box is a new, experimental way to keep parts of a program from stepping on each other: "Definitions loaded in a box are isolated in the box," so it "can isolate/separate monkey patches, changes of global/class variables, class/module definitions, and loaded native/ruby libraries from other boxes" (a "monkey patch" being code that reaches in and alters an existing class at runtime, handy but historically easy to have leak everywhere). Ruby 4.0 also continued work on Ractor, Ruby's tool for running code in parallel with isolated state, adding a new `Ractor::Port` class for passing messages between Ractors.

*Related:* [[the-christmas-release-tradition]] · [[ruby-3-0]] · [[yjit]]

## Sources
- Ruby 4.0.0 Released (official announcement, ruby-lang.org): https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/
