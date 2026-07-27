---
type: "story"
title: "RubyGems is born at RubyConf"
hook: "The way Rubyists install libraries began as an all-night coding dare at RubyConf 2003."
dates:
  - { date: 2004-03-14, label: "RubyGems first public release (Pi Day)" }
sources:
  - { title: "RubyGems (Wikipedia)", url: "https://en.wikipedia.org/wiki/RubyGems" }
  - { title: "Fowler on RubyGems (onrails.org, 2006)", url: "https://onrails.org/2006/07/20/fowler-on-rubygems.html" }
  - { title: "CPAN (Wikipedia; Perl's package archive, online since 1995)", url: "https://en.wikipedia.org/wiki/CPAN" }
---

**RubyGems**, the tool every Rubyist uses to install and manage libraries, got its start in a burst of overnight coding at **RubyConf 2003** in Austin, Texas.

First, the plain-English version. A **package manager** is the thing that fetches and installs reusable bundles of other people's code so you do not have to copy files around by hand. In Ruby, those bundles are called **gems**, and once RubyGems exists you install one by typing `gem install` followed by its name. Before RubyGems, there was no standard way to do this in Ruby, and sharing Ruby code was a lot more painful than it needed to be. RubyGems was not the first package manager anywhere: other languages had their own, most famously Perl's CPAN, online since 1995. What RubyGems did was give *Ruby* its first standard one, and it stuck.

The origin story is a small piece of Ruby folklore. At RubyConf 2003, David A. Black pressed Ruby's creator, [[matz]], about the language's missing package manager, and Matz gave a challenge of an answer: "if you build it, it will be included in ruby core." So a group did exactly that. Richard Kilmer, Chad Fowler, David Black, Paul Brannan, and [[jim-weirich]] spent the night coding, and had a working prototype to demo at the conference before it ended.

Development continued after everyone went home, and the first public release landed on **March 14, 2004**, which Rubyists happily note is **Pi Day** (3.14). RubyGems became so essential that it was eventually bundled into Ruby itself, and it remains the foundation that later tools like [[bundler]], which pins the exact set of gems a project needs, are built on top of.

*Related:* [[bundler]] · [[jim-weirich]] · [[matz]]

## Sources
- RubyGems (Wikipedia), what it is, `gem install`, the creators, RubyConf 2003 origin, March 14 2004 / Pi Day release: https://en.wikipedia.org/wiki/RubyGems
- Fowler on RubyGems (onrails.org, 2006), the RubyConf 2003 session, Matz's "if you build it" challenge, the overnight coding and demo: https://onrails.org/2006/07/20/fowler-on-rubygems.html
- CPAN (Wikipedia; Perl's package archive, online since 1995, predating RubyGems): https://en.wikipedia.org/wiki/CPAN
