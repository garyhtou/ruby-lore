---
type: "vocabulary"
title: "Monkey Patching"
hook: "Reopening an existing class at runtime to change it, for better and for worse."
sources:
  - { title: "Responsible Monkeypatching in Ruby (AppSignal)", url: "https://blog.appsignal.com/2021/08/24/responsible-monkeypatching-in-ruby.html" }
  - { title: "Monkey patch (Wikiquote)", url: "https://en.wikiquote.org/wiki/Monkey_patch" }
---

**Monkey patching** means reopening a class that already exists and changing or extending it at runtime, without editing its original source. Ruby makes this natural because its classes are "open": you can define the same class as many times as you like, and each new definition adds to what is already there, even for built-ins like `String`. The power is real, since you can teach an existing class a new trick in a few lines:

```ruby
class String
  def shout
    upcase + "!"
  end
end
"hi".shout  # => "HI!"
```

So is the danger: the last patch to load wins, there is no clean way to reach the original method, and a surprise patch can break code somewhere far away. Some Rubyists call it "duck punching," a name from a RailsConf 2007 talk where Patrick Ewing joked that if a duck is not making the noise you want, "you've got to just punch that duck until it returns what you expect".

*Related:* [[everything-is-an-object]] · [[duck-typing]]

## Sources
- Responsible Monkeypatching in Ruby (AppSignal): https://blog.appsignal.com/2021/08/24/responsible-monkeypatching-in-ruby.html
- Monkey patch (Wikiquote), the "punch that duck" quote, Patrick Ewing at RailsConf 2007: https://en.wikiquote.org/wiki/Monkey_patch
