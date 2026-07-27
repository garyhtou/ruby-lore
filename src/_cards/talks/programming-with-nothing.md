---
type: "talk"
title: "\"Programming with Nothing\" (Tom Stuart, 2011)"
hook: "Tom Stuart rebuilds numbers, booleans, and a whole running program in Ruby using nothing but procs."
sources:
  - { title: "Programming with Nothing (Tom Stuart's own write-up, tomstu.art)", url: "https://tomstu.art/programming-with-nothing" }
  - { title: "Ruby Manor 3 - Programming with Nothing (video, YouTube)", url: "https://www.youtube.com/watch?v=VUhlNx_-wYk" }
---

**"Programming with Nothing"** is a talk and companion [essay](https://tomstu.art/programming-with-nothing) by Tom Stuart that asks a wonderful question: how much can you still do in Ruby if you throw away almost everything? He removes all of Ruby's data types and keeps only the proc (an anonymous block of code), plus `Proc.new` and `Proc#call`, and then rebuilds numbers, booleans, lists, and strings out of nothing but those procs, using them to run a real program. He first gave it at the Ruby Manor 3 conference in London in 2011, and links the video and slides from his own page.

Here is the wow-factor for a newcomer. We think of a number like 3 as a basic building block, something the language just hands you. Tom shows it does not have to be: a number can instead be a little function that does something three times, a boolean can be a function that picks between two choices, and once you have those you can build addition, multiplication, and eventually the classic FizzBuzz program, all without ever typing a digit, a quote, or the word `class`. In his own framing, "In this alien world there is no data, only code."

What he is quietly demonstrating is the untyped lambda calculus, a model of computation from the 1930s, with the pieces built as Church encodings (a standard way of representing data purely as functions). You do not need any of that vocabulary to enjoy the trick, which is the point: it takes a deep result about what computation really is and makes you watch it happen in plain Ruby. Tom later expanded the material into his O'Reilly book *Understanding Computation*.

*Related:* [[y-not]] · [[wat]] · [[everything-is-an-object]]

## Sources
- Programming with Nothing (Tom Stuart's own write-up, tomstu.art; states the Ruby Manor talk, the proc-only rebuild, Church encodings, and the "no data, only code" line): https://tomstu.art/programming-with-nothing
- Ruby Manor 3 - Programming with Nothing (talk video, YouTube): https://www.youtube.com/watch?v=VUhlNx_-wYk
