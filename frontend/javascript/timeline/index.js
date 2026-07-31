// The scroll-driven scrubbable timeline on /timeline/.
//
// This is an ENHANCEMENT of the static `<ol class="timeline">` rendered by
// src/timeline.erb (see script/check_no_js_content.rb, the CI guard for the
// site's one hard rule: every fact/date/link must be real static HTML that
// works with JavaScript off). This module never creates, gates, or moves any
// timeline fact - it only animates DOM that already exists, plus one purely
// decorative rail-fill element it creates itself.
//
// The base CSS state of every `.timeline__entry` (in
// frontend/styles/components/listings.css) is fully visible, full stop -
// there is no CSS rule anywhere that sets it to `opacity: 0` by default.
// The "animate in from hidden" state is applied here via `gsap.set()`
// inline styles, and ONLY inside the `motionOK` branch of a
// `gsap.matchMedia()` context (prefers-reduced-motion: no-preference). That
// means:
//   - JS off: this module never runs. Every entry renders exactly as
//     authored - fully visible, no scrub.
//   - prefers-reduced-motion: reduce: the `motionOK` branch never executes,
//     so entries are never set to opacity 0 in the first place. The
//     rendered content is byte-for-byte the static Phase-2 list.
//   - If the OS setting changes live mid-session, `gsap.matchMedia()`
//     reverts every tween/set/ScrollTrigger created in the outgoing branch
//     automatically, so entries snap back to their authored (visible) CSS
//     state rather than getting stuck mid-animation.
//
// The journey: a garnet rail-fill draws itself down the timeline's spine as
// you scroll (the "walking the canon in time" read), and each entry eases
// up into place, scrubbed to scroll position rather than a one-shot reveal,
// so the whole thing tracks the scrollbar exactly and reverses cleanly on
// scroll-up. Only `transform`/`opacity` are animated (GPU-friendly, no
// layout thrash). Touch: this is plain vertical scroll-scrubbing with no
// pinning, so it works with a normal swipe on a phone exactly like desktop
// wheel/trackpad scroll - there's nothing touch-specific to wire up.

// ScrollTrigger itself isn't referenced directly here (the `scrollTrigger:`
// config on gsap.to() below is enough once the plugin is registered), but
// this import still runs frontend/javascript/lib/gsap.js's module body,
// which is where registration happens.
import { gsap } from "../lib/gsap.js"

const LIST_SELECTOR = ".timeline"
const ENTRY_SELECTOR = ".timeline__entry"

function buildRailFill(list) {
  const rail = document.createElement("div")
  rail.className = "timeline__rail-fill"
  rail.setAttribute("aria-hidden", "true")
  list.prepend(rail)
  return rail
}

export function initTimeline() {
  const list = document.querySelector(LIST_SELECTOR)
  if (!list) return // Lazy-init: only wire ScrollTriggers when the timeline exists on the page.

  const entries = Array.from(list.querySelectorAll(ENTRY_SELECTOR))
  if (entries.length === 0) return

  const mm = gsap.matchMedia()

  mm.add(
    {
      motionOK: "(prefers-reduced-motion: no-preference)",
    },
    (context) => {
      if (!context.conditions.motionOK) return

      list.classList.add("timeline--animated")

      const rail = buildRailFill(list)
      gsap.set(rail, { scaleY: 0, transformOrigin: "top center" })

      // The spine fills as the whole list scrolls through view. `end:
      // "bottom bottom"` (the list's own bottom edge reaching the
      // viewport's bottom edge) is deliberate, not the more obvious
      // "bottom 65%": a percentage-of-viewport end point requires a fixed
      // amount of scroll room to exist AFTER the list (e.g. a tall
      // footer) to ever be reachable. This page's footer is one short
      // line, so a "bottom 65%" end left the fill stuck around 84% at
      // the real bottom of the page (confirmed live). "bottom bottom" is
      // always reachable by construction - it resolves at or before the
      // document's true max scroll no matter how little trailing content
      // follows - and it reads naturally too ("the spine finishes
      // drawing once the whole list has scrolled into view").
      gsap.to(rail, {
        scaleY: 1,
        ease: "none",
        scrollTrigger: {
          trigger: list,
          start: "top 78%",
          end: "bottom bottom",
          scrub: 0.6,
          invalidateOnRefresh: true,
        },
      })

      // Each stop eases up into place, scrubbed to its own scroll band so
      // it tracks the scrollbar 1:1 and reverses cleanly scrolling back up.
      // Same "bottom bottom" reasoning as the rail above: anchoring the
      // end to the entry's OWN bottom edge reaching the viewport bottom
      // (rather than a "top X%" point further up the page) guarantees
      // every entry - including the last one, with almost no page left
      // below it - can always fully resolve to opaque once it has
      // scrolled into view, instead of getting stuck dimmed forever.
      gsap.set(entries, { opacity: 0, y: 32, scale: 0.985 })
      entries.forEach((entry) => {
        gsap.to(entry, {
          opacity: 1,
          y: 0,
          scale: 1,
          ease: "none",
          scrollTrigger: {
            trigger: entry,
            start: "top 90%",
            end: "bottom bottom",
            scrub: 0.5,
            invalidateOnRefresh: true,
          },
        })
      })

      // gsap.matchMedia's context auto-reverts every tween/set/ScrollTrigger
      // created above when this branch stops matching (OS setting flips to
      // reduced-motion live), so entries snap back to their visible CSS
      // authored state. This cleanup only needs to remove the element we
      // created ourselves.
      return () => {
        list.classList.remove("timeline--animated")
        rail.remove()
      }
    }
  )
}
