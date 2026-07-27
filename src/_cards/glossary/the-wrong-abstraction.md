---
type: "vocabulary"
title: "The Wrong Abstraction"
hook: "\"Duplication is far cheaper than the wrong abstraction.\" Sandi Metz's warning against over-tidying code."
sources:
  - { title: "The Wrong Abstraction (Sandi Metz, 2016)", url: "https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction" }
---

**The Wrong Abstraction** is [[sandi-metz]]'s idea that forcing similar-but-not-identical bits of code into one shared abstraction can end up worse than the repeated code it replaced. Her memorable line, first made in her RailsConf 2014 talk "All the Little Things" and later written up as a 2016 essay, is that **"duplication is far cheaper than the wrong abstraction."** The trap goes like this: you spot some duplication, extract it into one tidy shared method, and then reality sends you cases that are almost but not quite the same. So you add a parameter, then a conditional, then another, until the abstraction is a tangle serving several masters badly. Her fix is refreshingly humble: when an abstraction is wrong, "the fastest way forward is back," meaning you re-inline the shared code back into each caller, delete the parts each one does not need, and start over from what you now actually know. The idea has become a common counterweight to over-eager DRY ("Don't Repeat Yourself") advice, and Sandi explores it further alongside her frequent collaborator [[katrina-owen]], with whom she co-wrote the book *99 Bottles of OOP*.

*Related:* [[sandi-metz]] · [[katrina-owen]]

## Sources
- The Wrong Abstraction (Sandi Metz, 2016): https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction
