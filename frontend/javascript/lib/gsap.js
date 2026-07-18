// Central GSAP wiring for the whole site.
//
// Every other module (this task's easter eggs, and the later scrubbable
// timeline / _why scroll-telling tasks - 2b.2 and 2b.3) imports `gsap` and
// `ScrollTrigger` from *this* file instead of `"gsap"` / `"gsap/ScrollTrigger"`
// directly. That keeps plugin registration (`gsap.registerPlugin(...)`) to a
// single call site no matter how many modules end up using GSAP.
//
// `prefersReducedMotion()` is exported alongside it because nearly every
// animation module needs to check it before running a tween - the site's
// motion convention (see frontend/styles/base.css's
// `@media (prefers-reduced-motion: reduce)` block) is "respect it everywhere",
// so it lives next to the tool everyone reaches for to animate.

import gsap from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"

gsap.registerPlugin(ScrollTrigger)

/**
 * Whether the user has asked the OS/browser for reduced motion. Read live
 * (not cached) since it can be evaluated at any point during the page's
 * life, e.g. right before a user-triggered animation fires.
 * @returns {boolean}
 */
export function prefersReducedMotion() {
  return (
    typeof window !== "undefined" &&
    typeof window.matchMedia === "function" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches
  )
}

export { gsap, ScrollTrigger }
