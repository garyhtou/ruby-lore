---
type: "vocabulary"
title: "puts debugging"
hook: "Finding a bug by sprinkling humble print statements, no fancy debugger required."
sources:
  - { title: "I am a puts debuggerer (Aaron Patterson, 2016)", url: "https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer/" }
---

**puts debugging** is the time-honored practice of tracking down a bug by scattering `puts` statements through your code to print out values as it runs, then reading the output to see where things went wrong. `puts` is Ruby's plainest way to print a line of text to the screen (it is short for "put string"), so `puts user.name` simply shows you what `user.name` actually is at that moment. It is the low-tech alternative to a full step-through debugger, and it is beloved partly because Ruby's own [[tenderlove]] (Aaron Patterson, a longtime Ruby and Rails core contributor) has cheerfully championed it. In a 2016 post titled "I am a puts debuggerer," he wrote: "I am a `puts` debuggerer. I don't say this to disparage people that use a Real Debugger. I think Real Debuggers are great, I've just never taken the time to learn one well." If you have ever solved a problem this way and felt a little sheepish, take heart: you are in very good company.

*Related:* [[tenderlove]]

## Sources
- I am a puts debuggerer (Aaron Patterson, 2016): https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer/
