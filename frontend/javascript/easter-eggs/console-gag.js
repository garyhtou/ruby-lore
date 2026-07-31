// The `puts` gag: the classic "open devtools, find a friendly message"
// easter egg, styled to look like Ruby's `puts` in a terminal. One tasteful
// message on load - not console spam, and never anything but a courteous
// aside (no tracking, no data).

export function initConsoleGag() {
  const style = [
    "background: #9B1B30",
    "color: #F7F1E6",
    "padding: 2px 8px",
    "border-radius: 3px 0 0 3px",
    "font-family: 'JetBrains Mono', monospace",
    "font-weight: 700",
  ].join(";")

  const plain = "font-family: 'JetBrains Mono', monospace;"

  // eslint-disable-next-line no-console
  console.log(
    "%c puts %c \"Hey, fellow Rubyist, welcome behind the curtain.\"\n\n" +
      "You're reading Ruby Lore's console, which means you probably still open\n" +
      "devtools out of habit from debugging with puts. Respect.\n\n" +
      "This whole site is a love letter to Ruby's history: warts, chunky\n" +
      "bacon, and all. If you spot a fact worth fixing or a story worth adding,\n" +
      "we'd love to hear it.\n\n" +
      "we’re chunky bacon. 🥓",
    style,
    plain
  )
}
