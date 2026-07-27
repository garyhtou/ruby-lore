---
type: "vocabulary"
title: "Duck Typing"
hook: "Judge an object by what it can do, not by the class it belongs to."
sources:
  - { title: "Duck Typing (Devopedia)", url: "https://devopedia.org/duck-typing" }
---

**Duck typing** is the habit of judging an object by what it can do, not by what class it is: if an object responds to the methods you need, Ruby will happily use it, whatever its type. The name comes from the old saying, "if it walks like a duck and quacks like a duck, it must be a duck." So a method that calls `thing.quack` works for any `thing` that defines a `quack` method, whether it is a Duck, a Dog, or a rubber toy. The earliest documented use of the term among programmers is credited to Alex Martelli in the Python community around 2000, and it went on to become one of the signature ideas Rubyists reach for when they describe why the language feels so flexible.

*Related:* [[dave-thomas]] · [[everything-is-an-object]] · [[monkey-patching]]

## Sources
- Duck Typing (Devopedia), history and attribution: https://devopedia.org/duck-typing
