// The fox "CHUNKY BACON!" shout.
//
// Trigger: clicking the ruby-lozenge wordmark ornament (`.site-brand__mark`)
// in the navbar (src/_components/shared/navbar.erb). That span is decorative
// and `aria-hidden` today - a slot left for the future fox mark -
// so hijacking clicks on just that small diamond doesn't take away any real
// functionality: the rest of the "Ruby Lore" wordmark, and the "Home" link in
// the primary nav, both still navigate home exactly as before. With JS off
// the mark is inert decoration, same as today.
//
// _why the poignant guide's catchphrase ("we're chunky bacon!") is the
// site's whole vibe, hence the wink. The bubble now leads with 2b.4's real
// fox mark (a decorative, aria-hidden SVG twin of the masthead fox) so it
// reads as the fox itself shouting, with the shout text in an adjacent
// live-region span. The trigger and animation logic are untouched.

import { gsap, prefersReducedMotion } from "../lib/gsap.js"

const SHOUTS = [
  "CHUNKY BACON!",
  "we're chunky bacon!",
  "🥓 CHUNKY BACON 🥓",
  "puts \"chunky bacon\"",
]

// The masthead fox, redrawn here as decorative bubble art. Kept in sync with
// src/_components/shared/navbar.erb; colours come from the .fox-mark tokens the
// bubble CSS sets for its garnet ground.
const FOX_SVG =
  '<svg class="fox-mark" viewBox="0 0 64 64" aria-hidden="true" focusable="false">' +
  '<path fill="var(--fox-fur)" stroke="var(--fox-fur)" stroke-width="3" stroke-linejoin="round" d="M11 8 L26 21 L32 19 L38 21 L53 8 L52 26 L48 38 L40 49 L32 55 L24 49 L16 38 L12 26 Z"/>' +
  '<path fill="var(--fox-ear)" stroke="var(--fox-ear)" stroke-width="1.4" stroke-linejoin="round" d="M15 13 L24 21 L18 24 Z"/>' +
  '<path fill="var(--fox-ear)" stroke="var(--fox-ear)" stroke-width="1.4" stroke-linejoin="round" d="M49 13 L40 21 L46 24 Z"/>' +
  '<path fill="var(--fox-muzzle)" d="M24 33 Q32 30 40 33 Q45 42 38 50 Q32 56 26 50 Q19 42 24 33 Z"/>' +
  '<ellipse fill="var(--fox-ink)" cx="22.5" cy="29" rx="2.5" ry="3.4" transform="rotate(20 22.5 29)"/>' +
  '<ellipse fill="var(--fox-ink)" cx="41.5" cy="29" rx="2.5" ry="3.4" transform="rotate(-20 41.5 29)"/>' +
  '<path fill="var(--fox-ink)" d="M29 45 Q32 43 35 45 Q35 49 32 51 Q29 49 29 45 Z"/>' +
  "</svg>"

let bubbleEl = null
let bubbleTextEl = null
let activeTween = null

function ensureBubble() {
  if (bubbleEl) return bubbleEl

  bubbleEl = document.createElement("div")
  bubbleEl.className = "chunky-bacon-bubble"
  bubbleEl.setAttribute("role", "status")
  bubbleEl.setAttribute("aria-live", "polite")

  const foxEl = document.createElement("span")
  foxEl.className = "chunky-bacon-bubble__fox"
  foxEl.setAttribute("aria-hidden", "true")
  foxEl.innerHTML = FOX_SVG
  bubbleEl.appendChild(foxEl)

  // The shout text lives in its own span so updating it (not the whole bubble)
  // keeps the decorative fox in place and is what the live region announces.
  bubbleTextEl = document.createElement("span")
  bubbleTextEl.className = "chunky-bacon-bubble__text"
  bubbleEl.appendChild(bubbleTextEl)

  document.body.appendChild(bubbleEl)
  return bubbleEl
}

function positionNear(anchorEl) {
  const rect = anchorEl.getBoundingClientRect()
  const bubble = ensureBubble()
  // Provisionally place it, measure, then nudge so it never runs off-screen.
  bubble.style.left = `${rect.left}px`
  bubble.style.top = `${rect.bottom + 10}px`

  const bubbleRect = bubble.getBoundingClientRect()
  const overflowRight = bubbleRect.right - (window.innerWidth - 8)
  if (overflowRight > 0) {
    bubble.style.left = `${rect.left - overflowRight}px`
  }
}

function shoutFox(anchorEl) {
  const bubble = ensureBubble()
  bubbleTextEl.textContent = SHOUTS[Math.floor(Math.random() * SHOUTS.length)]
  positionNear(anchorEl)

  if (activeTween) activeTween.kill()

  if (prefersReducedMotion()) {
    // Still show the delight, just skip the pop/wiggle choreography.
    gsap.set(bubble, { opacity: 1, scale: 1, rotate: 0 })
    activeTween = gsap.to(bubble, { opacity: 0, duration: 0.25, delay: 1.4 })
    return
  }

  const tl = gsap.timeline()
  tl.fromTo(
    bubble,
    { opacity: 0, scale: 0.4, y: 8, rotate: -6 },
    { opacity: 1, scale: 1, y: 0, rotate: -2, duration: 0.35, ease: "back.out(2.4)" }
  )
    .to(bubble, { rotate: 2, duration: 0.18, ease: "sine.inOut" })
    .to(bubble, { rotate: -1, duration: 0.16, ease: "sine.inOut" })
    .to(bubble, { rotate: 0, duration: 0.14, ease: "sine.inOut" })
    .to(bubble, { opacity: 0, y: -6, duration: 0.4, ease: "power1.in", delay: 1.1 })

  activeTween = tl
}

export function initFoxShout() {
  const mark = document.querySelector(".site-brand__mark")
  if (!mark) return

  mark.addEventListener("click", (event) => {
    // Only the tiny ornament triggers the shout instead of navigating home;
    // clicking the rest of the wordmark (or the "Home" nav link) still works.
    event.preventDefault()
    event.stopPropagation()
    shoutFox(mark)
  })
}
