// The cornerstone _why scroll-telling on /people/why-the-lucky-stiff/.
//
// This is an ENHANCEMENT of the static article rendered by src/_layouts/card.erb
// from src/_cards/people/why-the-lucky-stiff.md. Like the timeline (2b.2), it
// only animates DOM that already exists (plus a couple of purely decorative
// elements it creates itself). It never creates, gates, hides, or moves any
// fact, paragraph, link, or heading text as the sole copy of that content.
//
// The site's one hard rule (script/check_no_js_content.rb): every fact/date/link
// is real static HTML that works with JavaScript OFF. Everything below is
// applied on TOP of already-readable prose and RESOLVES BACK to it:
//   - JS off: this module never runs. The full clean article renders as authored.
//   - prefers-reduced-motion: reduce: the `motionOK` branch of gsap.matchMedia()
//     never executes (hard early-return before any hiding/dimming/scramble code),
//     so nothing is ever dimmed, offset, wrapped, or scrambled. The rendered
//     content is the clean static article, byte-for-byte.
//   - If the OS setting flips to reduced-motion live mid-session, matchMedia
//     reverts every tween/set/ScrollTrigger created in the outgoing branch, and
//     the returned cleanup restores the one heading we briefly settle and unwraps
//     the one decorative wrapper we add - so the clean article snaps back.
//
// R31 (the site's most important constraint): _why chose anonymity. This module
// adds NO text, caption, label, alt, tooltip, aria-label, data attribute, source,
// or link that names, initializes, obfuscates, hints at, or points toward his
// legal identity. The one text effect (a brief character-settle) operates ONLY on
// the EXISTING, name-respectful heading "The community caught him" - a phrase
// about the community's rescue of his WORK, never about identity - and resolves
// exactly back to that heading. Its transient glyphs are random abstract
// characters that never spell or hint at anything; word spacing is preserved so
// no name can emerge. No new external link is introduced anywhere here.
//
// Tone: reverent, not flashy. Three quiet beats that let scroll carry the
// emotion - a hush falling over the disappearance, the pages easing back together
// as the community catches him, and a soft warmth returning for Whyday. Only
// transform/opacity are animated (GPU-friendly), plus the one text-settle that
// resolves to clean heading text. Native vertical scroll drives everything (no
// pinning, no scroll traps), so a phone swipe behaves exactly like a desktop
// scroll.

import { gsap, ScrollTrigger } from "../lib/gsap.js"

// Per-page guard: only ever run on the _why cornerstone. We key off the URL
// (trailing-slash / index.html tolerant) rather than adding a layout hook, so
// card.erb stays untouched. Each scene additionally guards on its heading's
// presence, so a content restructure degrades to a safe no-op.
function isWhyPage() {
  const path = window.location.pathname
    .replace(/index\.html?$/i, "")
    .replace(/\/+$/, "")
  return path.endsWith("/people/why-the-lucky-stiff")
}

// A "section" is a heading plus every sibling up to (not including) the next
// <h2> - the flat block structure card.erb emits inside .card__body.
function collectSection(headingId) {
  const heading = document.getElementById(headingId)
  if (!heading) return { heading: null, nodes: [] }
  const nodes = [heading]
  let el = heading.nextElementSibling
  while (el && el.tagName !== "H2") {
    nodes.push(el)
    el = el.nextElementSibling
  }
  return { heading, nodes }
}

// Runtime-only wrapper so a scene can host a positioned decorative layer. Never
// present in the static HTML; removed again by unwrap() on cleanup/revert.
function wrap(nodes, className) {
  const first = nodes[0]
  const wrapper = document.createElement("div")
  wrapper.className = className
  first.parentNode.insertBefore(wrapper, first)
  nodes.forEach((node) => wrapper.appendChild(node))
  return wrapper
}

function unwrap(wrapper) {
  const parent = wrapper.parentNode
  if (!parent) return
  while (wrapper.firstChild) parent.insertBefore(wrapper.firstChild, wrapper)
  parent.removeChild(wrapper)
}

// A brief, soft character-settle that resolves an EXISTING heading back to its
// exact authored text. See the R31 note at the top of this file: this only ever
// runs on the name-respectful "The community caught him" heading, uses abstract
// random glyphs, preserves spaces, and always ends on the original string.
const SETTLE_GLYPHS = "abcdefghijklmnopqrstuvwxyz·—+*"

function makeHeadingSettle(heading) {
  // Guard: only settle a plain-text heading (no inline markup to clobber).
  if (!heading || heading.children.length > 0) return null
  const original = heading.textContent
  if (!original || !original.trim()) return null

  let tween = null
  const restore = () => {
    if (tween) tween.kill()
    heading.textContent = original
  }
  const run = () => {
    const proxy = { p: 0 }
    tween = gsap.to(proxy, {
      p: 1,
      duration: 0.9,
      ease: "power1.out",
      onUpdate: () => {
        const resolved = Math.floor(proxy.p * original.length)
        let out = ""
        for (let i = 0; i < original.length; i += 1) {
          const ch = original[i]
          // Resolved-so-far chars and every space stay put; the rest flicker
          // through random abstract glyphs. Never spells anything.
          out +=
            i < resolved || ch === " "
              ? ch
              : SETTLE_GLYPHS[Math.floor(Math.random() * SETTLE_GLYPHS.length)]
        }
        heading.textContent = out
      },
      onComplete: () => {
        heading.textContent = original
      },
    })
  }
  return { run, restore }
}

export function initWhy() {
  if (!isWhyPage()) return

  const body = document.querySelector(".card .card__body")
  if (!body) return

  const mm = gsap.matchMedia()

  mm.add(
    { motionOK: "(prefers-reduced-motion: no-preference)" },
    (context) => {
      // Hard early-return before ANY dim/offset/wrap/scramble code, so
      // reduced-motion users never reach a hiding state.
      if (!context.conditions.motionOK) return

      body.classList.add("why--animated")
      const teardown = []

      // --- Scene 1: the disappearance - a hush passes over ------------------
      // Everything "went dark all at once." As the section reaches reading
      // position the light quietly drains from it (a shadow passing over),
      // then lifts again as you scroll on. Purely opacity, floored well within
      // legibility (~0.66 of already ~13:1 ink-on-parchment), scrubbed to the
      // scrollbar and resolving to fully opaque by the section's end.
      const disappearance = collectSection("the-disappearance")
      if (disappearance.nodes.length) {
        const nodes = disappearance.nodes
        const dim = gsap
          .timeline({
            scrollTrigger: {
              trigger: nodes[0],
              start: "top 72%",
              endTrigger: nodes[nodes.length - 1],
              end: "bottom 40%",
              scrub: 0.6,
              invalidateOnRefresh: true,
            },
          })
          .to(nodes, { opacity: 0.66, ease: "sine.inOut", duration: 1 })
          .to(nodes, { opacity: 1, ease: "sine.inOut", duration: 1 })
        teardown.push(() => dim.scrollTrigger && dim.scrollTrigger.kill())
      }

      // --- Scene 2: the community caught him - the pages reassemble ---------
      // The paragraphs ease up and gather into place (fragments coming back
      // together), and the heading briefly settles into focus - "reassembled
      // the pages." The heading settle is a one-shot that always resolves to
      // the clean, name-respectful heading text; skipped entirely under
      // reduced motion (this branch never runs) and restored on teardown.
      const rescue = collectSection("the-community-caught-him")
      if (rescue.heading && rescue.nodes.length) {
        const paragraphs = rescue.nodes.filter((n) => n !== rescue.heading)
        if (paragraphs.length) {
          gsap.set(paragraphs, { opacity: 0.15, y: 26 })
          const gather = gsap.to(paragraphs, {
            opacity: 1,
            y: 0,
            ease: "none",
            stagger: 0.05,
            scrollTrigger: {
              trigger: rescue.heading,
              start: "top 82%",
              endTrigger: rescue.nodes[rescue.nodes.length - 1],
              end: "bottom bottom",
              scrub: 0.5,
              invalidateOnRefresh: true,
            },
          })
          teardown.push(() => gather.scrollTrigger && gather.scrollTrigger.kill())
        }

        const settle = makeHeadingSettle(rescue.heading)
        if (settle) {
          const trigger = ScrollTrigger.create({
            trigger: rescue.heading,
            start: "top 78%",
            once: true,
            onEnter: settle.run,
          })
          teardown.push(() => {
            trigger.kill()
            settle.restore()
          })
        }
      }

      // --- Scene 3: Whyday - warmth returns --------------------------------
      // The hopeful turn. The section gently lifts into place while a soft
      // fox-orange / brass glow eases in behind it - the light coming back,
      // the celebration. The glow is a decorative element created here (never
      // in the static HTML), sits behind the text (legibility untouched), and
      // rests at a gentle warmth. Removed and unwrapped on teardown/revert.
      const whyday = collectSection("whyday-august-19")
      if (whyday.nodes.length) {
        const wrapper = wrap(whyday.nodes, "why-glow-scene")
        const glow = document.createElement("div")
        glow.className = "why-glow"
        glow.setAttribute("aria-hidden", "true")
        wrapper.prepend(glow)

        gsap.set(glow, { opacity: 0 })
        gsap.set(whyday.nodes, { opacity: 0.2, y: 22 })
        const lift = gsap
          .timeline({
            scrollTrigger: {
              trigger: wrapper,
              start: "top 80%",
              end: "bottom 62%",
              scrub: 0.6,
              invalidateOnRefresh: true,
            },
          })
          .to(whyday.nodes, { opacity: 1, y: 0, ease: "none", stagger: 0.05 }, 0)
          .to(glow, { opacity: 0.55, ease: "none" }, 0)

        teardown.push(() => {
          lift.scrollTrigger && lift.scrollTrigger.kill()
          glow.remove()
          unwrap(wrapper)
        })
      }

      // matchMedia auto-reverts every gsap tween/set/ScrollTrigger created
      // above when this branch stops matching (OS flips to reduced-motion),
      // snapping nodes back to their authored CSS-visible state. This cleanup
      // only handles what we created/mutated ourselves: kill our triggers,
      // restore the settled heading, and remove the decorative wrapper/glow.
      return () => {
        body.classList.remove("why--animated")
        teardown.forEach((fn) => fn())
      }
    }
  )
}
