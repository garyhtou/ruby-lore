---
type: "talk"
title: "\"Y Not? Adventures in Functional Programming\" (Jim Weirich, 2012)"
hook: "Jim Weirich derives the Y combinator live in Ruby, and makes one of computer science's hardest ideas feel like a gift."
sources:
  - { title: "Y Not? Adventures in Functional Programming (InfoQ presentation page)", url: "https://www.infoq.com/presentations/Y-Combinator/" }
  - { title: "Ruby Conf 12 - Y Not (Confreaks video, YouTube)", url: "https://www.youtube.com/watch?v=FITJMJjASUs" }
  - { title: "Jim Weirich (Wikipedia)", url: "https://en.wikipedia.org/wiki/Jim_Weirich" }
---

**"Y Not? Adventures in Functional Programming"** is a talk by [[jim-weirich]] in which he builds the **Y combinator** from scratch, live, in Ruby, starting from tiny lambdas (nameless little functions) and refactoring his way to it one small step at a time. He gave it at [RubyConf 2012](https://www.youtube.com/watch?v=FITJMJjASUs), and a version was also recorded at Strange Loop the same year.

So what is the Y combinator, and why should a newcomer care? Normally, for a function to call itself (to recurse), it needs a name to call. The Y combinator is a clever piece of plumbing that lets a function recurse without ever being given a name, using nothing but functions that take and return other functions. It is a classic "how is that even possible" result from the mathematics that underlies programming, and the official summary puts Jim's goal plainly: he "uses Y-Combinator as a tool to explain the nature of functional programming." Along the way he walks through currying (turning a function of many arguments into a chain of one-argument functions) and lambdas, so you can follow each move even if you have never met the destination.

The reason Rubyists still pass this talk around is not really the combinator. It is the teaching. Jim was known across the community for making genuinely hard topics feel approachable, and here he takes one of the field's famous head-scratchers and derives it with such calm, playful patience that you arrive at the answer almost by accident, grinning. Watch it as a masterclass in explaining something difficult with joy.

*Related:* [[jim-weirich]] · [[programming-with-nothing]] · [[wat]]

## Sources
- Y Not? Adventures in Functional Programming (InfoQ presentation page, official summary): https://www.infoq.com/presentations/Y-Combinator/
- Ruby Conf 12 - Y Not (Confreaks video, YouTube): https://www.youtube.com/watch?v=FITJMJjASUs
- Jim Weirich (Wikipedia, confirms the RubyConf 2012 talk): https://en.wikipedia.org/wiki/Jim_Weirich
