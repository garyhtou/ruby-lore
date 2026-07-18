// The Konami code: up up down down left right left right b a.
//
// Trigger: typing the classic sequence anywhere on the page (not while
// focus is inside a form control, so it never fights with someone actually
// typing "ba" into a search box or textarea). On match, a garnet banner
// unlocks with a nod to _why the poignant guide, plus a burst of falling
// bacon/fox/ruby emoji for veterans to screenshot.
//
// This is celebratory chrome only - it never gates or reveals page content,
// so with JS off (or if the sequence is never entered) the page is
// unaffected either way.

import { gsap, prefersReducedMotion } from "../lib/gsap.js"

const SEQUENCE = [
  "ArrowUp",
  "ArrowUp",
  "ArrowDown",
  "ArrowDown",
  "ArrowLeft",
  "ArrowRight",
  "ArrowLeft",
  "ArrowRight",
  "b",
  "a",
]

const CONFETTI_EMOJI = ["🥓", "🦊", "💎", "📜"]
const CONFETTI_COUNT = 24

let progress = 0

function isTypingTarget(target) {
  if (!(target instanceof Element)) return false
  const tag = target.tagName
  return tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT" || target.isContentEditable
}

function runConfettiBurst() {
  const field = document.createElement("div")
  field.className = "konami-confetti"
  field.setAttribute("aria-hidden", "true")
  document.body.appendChild(field)

  const pieces = []
  for (let i = 0; i < CONFETTI_COUNT; i++) {
    const piece = document.createElement("span")
    piece.className = "konami-confetti__piece"
    piece.textContent = CONFETTI_EMOJI[i % CONFETTI_EMOJI.length]
    piece.style.left = `${Math.random() * 100}vw`
    field.appendChild(piece)
    pieces.push(piece)
  }

  gsap.set(pieces, { opacity: 1 })
  pieces.forEach((piece) => {
    gsap.to(piece, {
      y: window.innerHeight + 80,
      x: `+=${gsap.utils.random(-80, 80)}`,
      rotate: gsap.utils.random(-260, 260),
      duration: gsap.utils.random(1.6, 2.6),
      delay: gsap.utils.random(0, 0.5),
      ease: "power1.in",
    })
  })

  gsap.to(field, {
    opacity: 0,
    duration: 0.4,
    delay: 2.9,
    onComplete: () => field.remove(),
  })
}

function showBanner() {
  const banner = document.createElement("div")
  banner.className = "konami-banner"
  banner.setAttribute("role", "status")
  banner.setAttribute("aria-live", "polite")
  banner.innerHTML =
    'Achievement unlocked: True Rubyist<small>we’re chunky bacon, and so are you 🥓</small>'
  document.body.appendChild(banner)

  const reduced = prefersReducedMotion()
  const tl = gsap.timeline({ onComplete: () => banner.remove() })

  if (reduced) {
    tl.set(banner, { opacity: 1, y: 0 })
      .to(banner, { opacity: 0, duration: 0.3, delay: 2.4 })
    return
  }

  tl.fromTo(
    banner,
    { opacity: 0, y: -16, scale: 0.92 },
    { opacity: 1, y: 0, scale: 1, duration: 0.5, ease: "back.out(1.8)" }
  ).to(banner, { opacity: 0, y: -10, duration: 0.5, ease: "power1.in", delay: 2.2 })
}

function unlock() {
  showBanner()
  if (!prefersReducedMotion()) runConfettiBurst()
}

export function initKonamiCode() {
  window.addEventListener("keydown", (event) => {
    if (isTypingTarget(event.target)) {
      progress = 0
      return
    }

    const expected = SEQUENCE[progress]
    const key = event.key.length === 1 ? event.key.toLowerCase() : event.key
    const matches = expected.length === 1 ? key === expected : event.key === expected

    if (matches) {
      progress += 1
      if (progress === SEQUENCE.length) {
        progress = 0
        unlock()
      }
    } else {
      // Allow the sequence to restart on the very key that broke it, in
      // case it happens to be the start of a fresh attempt (e.g. mistyped
      // and re-began with Up).
      progress = key === SEQUENCE[0] || event.key === SEQUENCE[0] ? 1 : 0
    }
  })
}
