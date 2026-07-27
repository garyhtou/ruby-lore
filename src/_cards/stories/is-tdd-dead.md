---
type: "story"
title: "Is TDD Dead?"
hook: "A blog post that started a fight, and a fight that stayed remarkably friendly."
dates:
  - { date: 2014-04-23, label: "\"TDD is dead. Long live testing.\" published, Apr 23 2014" }
sources:
  - { title: "TDD is dead. Long live testing. (DHH, 2014)", url: "https://dhh.dk/2014/tdd-is-dead-long-live-testing.html" }
  - { title: "Is TDD Dead? (Martin Fowler, 2014)", url: "https://martinfowler.com/articles/is-tdd-dead/" }
---

On **April 23, 2014**, [[dhh]] published a blog post titled **"TDD is dead. Long live testing."** **TDD** stands for **Test-Driven Development**: a practice, popularized by Kent Beck, where you write an automated test describing what code should do *before* you write the code itself, then make the test pass. The idea of TDD is not up for debate here; only DHH's argument about it is.

DHH's claim was not that testing is bad. He is emphatic that automated tests matter. His argument was narrower: that writing tests strictly first, as a rule, had for him turned into what he called "test-first fundamentalism," which he compared to "abstinence-only sex ed: An unrealistic, ineffective morality campaign". He wrote, "My name is David, and I do not write software test-first," and argued that designing code around test-first mocking could produce "test-induced design damage". The post grew out of his keynote at RailsConf 2014, where he had raised the same concerns.

## The part everyone remembers: it stayed kind

What happened next is the reason the story is worth telling. Instead of a flame war, it became a conversation. Martin Fowler, a well-known writer on software design, sent DHH a note, they talked, Kent joined, and the three agreed to hash it out in public. The result was a series of recorded video hangouts called **"Is TDD Dead?"**, five roughly half-hour episodes running from May 9 to June 4, 2014, each with written minutes.

Martin summed up the origin plainly: "David had a similar discussion with Kent, and Kent suggested that we continue the discussion with all three of us, and make the conversation public". In the exchange, DHH questioned test-first as a default, Kent defended TDD as one valuable tool among many, and Martin took a context-first middle ground, drawing a line between self-testing code in general and strict test-first TDD specifically. Three people who disagreed sat down, stayed generous, and tried to actually understand each other. Whether TDD is right for you is a call the series deliberately leaves to you, and so does this card.

*Related:* [[dhh]] · [[rails-from-basecamp]]

## Sources
- TDD is dead. Long live testing. (DHH, April 23, 2014): https://dhh.dk/2014/tdd-is-dead-long-live-testing.html
- Is TDD Dead? (Martin Fowler, series index and minutes, 2014): https://martinfowler.com/articles/is-tdd-dead/
